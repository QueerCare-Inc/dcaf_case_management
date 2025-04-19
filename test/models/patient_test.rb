require 'test_helper'

class PatientTest < ActiveSupport::TestCase
  extend Minitest::OptionalRetry

  before do
    @user = create :user
    @region = create :region
    @patient = create :patient, emergency_contact_phone: '111-222-3333',
                                emergency_contact: 'Yolo',
                                region: @region

    @patient2 = create :patient, emergency_contact_phone: '333-222-3333',
                                 emergency_contact: 'Foobar',
                                 region: @region
    @patient.calls.create attributes_for(:call, status: :reached_patient)
    @call = @patient.calls.first
    create_language_config
  end

  describe 'callbacks' do
    before do
      @new_patient = build :patient, name: '  Name With Whitespace  ',
                                     emergency_contact: ' also name with whitespace ',
                                     emergency_contact_relationship: '  something ',
                                     primary_phone: '111-222-3333',
                                     emergency_contact_phone: '999-888-7777'
    end

    it 'should clean fields before save' do
      @new_patient.save
      assert_equal 'Name With Whitespace', @new_patient.name
      assert_equal 'also name with whitespace', @new_patient.emergency_contact
      assert_equal 'something', @new_patient.emergency_contact_relationship
      assert_equal '1112223333', @new_patient.primary_phone
      assert_equal '9998887777', @new_patient.emergency_contact_phone
    end

    it 'should init a fulfillment after creation' do
      assert_nil @new_patient.fulfillment
      @new_patient.save
      @new_patient.reload
      assert_not_nil @new_patient.fulfillment
    end
  end

  describe 'validations' do
    it 'should build' do
      assert @patient.valid?
    end

    it 'requires a name' do
      @patient.name = nil
      assert_not @patient.valid?
    end

    it 'requires a primary phone' do
      @patient.primary_phone = nil
      assert_not @patient.valid?
    end

    %w[primary_phone emergency_contact_phone].each do |phone|
      it "should enforce a max length of 10 for #{phone}" do
        @patient[phone] = '123-456-789022'
        assert_not @patient.valid?
      end

      it "should clean before validation for #{phone}" do
        @patient[phone] = '111-222-3333'
        @patient.save
        assert_equal '1112223333', @patient[phone]
      end
    end

    %w[intake_date name primary_phone].each do |field|
      it "should enforce presence of #{field}" do
        @patient[field.to_sym] = nil
        assert_not @patient.valid?
      end
    end

    it 'should require procedure_date to be after intake_date' do
      # when initial call date is nil
      @patient.procedure_date = '2016-05-01'
      @patient.intake_date = nil
      assert_not @patient.valid?
      # when initial call date is after appointment date
      @patient.intake_date = '2016-09-01'
      assert_not @patient.valid?
      # when appointment date is nil
      @patient.procedure_date = nil
      assert @patient.valid?
      # when appointment date is after initial call date
      @patient.procedure_date = '2016-08-01'
      assert @patient.valid?
    end

    it 'should save the identifer' do
      assert_equal @patient.identifier,
                   "#{@patient.region.name[0]}#{@patient.primary_phone[-5]}-#{@patient.primary_phone[-4..-1]}"
    end

    it 'should enforce unique phone numbers' do
      @patient.primary_phone = '111-222-3333'
      @patient.save
      assert @patient.valid?

      @patient2.primary_phone = '111-222-3333'
      assert_not @patient2.valid?
    end

    it 'should throw two different error messages for duplicates found on same region versus different region' do
      region2 = create :region
      region3 = create :region
      marylandPatient = create :patient, name: 'Susan A in MD',
                                         primary_phone: '777-777-7777',
                                         region: region2
      sameRegionDuplicate = create :patient, name: 'Susan B in MD',
                                             region: region2
      diffRegionDuplicate = create :patient, name: 'Susan B in VA',
                                             region: region3

      sameRegionDuplicate.primary_phone = '777-777-7777'
      diffRegionDuplicate.primary_phone = '777-777-7777'

      sameRegionDuplicate.save
      diffRegionDuplicate.save

      assert_not sameRegionDuplicate.valid?
      assert_not diffRegionDuplicate.valid?

      error1 = sameRegionDuplicate.errors.messages[:this_phone_number_is_already_taken]
      error2 = diffRegionDuplicate.errors.messages[:this_phone_number_is_already_taken]

      assert_not_equal error1, error2
    end

    it 'should validate zipcode format' do
      # wrong len
      @patient.zipcode = '000'
      assert_not @patient.valid?

      # disallowed characters
      @patient.zipcode = 'Z6B 1A7'
      assert_not @patient.valid?

      ## zip +4
      @patient.zipcode = '00000-1111'
      assert @patient.valid?

      @patient.zipcode = '123456789'
      assert @patient.valid?
      assert_equal '12345-6789', @patient.zipcode

      @patient.zipcode = '00000-111'
      assert_not @patient.valid?

      @patient.zipcode = '00000-11111'
      assert_not @patient.valid?

      @patient.zipcode = '12345'
      @patient.save
      assert @patient.valid?
    end
  end

  describe 'callbacks' do
    describe 'clean_fields' do
      %w[name emergency_contact].each do |field|
        it "should strip whitespace from before and after #{field}" do
          @patient[field] = '   Yolo Goat   '
          @patient.save
          assert_equal 'Yolo Goat', @patient[field]
        end
      end

      %w[primary_phone emergency_contact_phone].each do |field|
        it "should remove nondigits on save from #{field}" do
          @patient[field] = '111-222-3333'
          @patient.save
          assert_equal '1112223333', @patient[field]
        end
      end
    end

    describe 'confirm still shared' do
      before do
        create :clinic
        @patient = create :patient, shared_flag: true,
                                    clinic: Clinic.first,
                                    procedure_date: 2.days.from_now
      end
    end

    describe 'blow away associated objects on destroy' do
      it 'should nuke associated events in addition to the patient on destroy' do
        create :call_list_entry, patient: @patient
        assert_difference 'Event.count', -1 do
          assert_difference 'CallListEntry.count', -1 do
            @patient.destroy
          end
        end
      end
    end

    describe 'update regions for call list entries on patient change' do
      it 'should update call list entries to push them to the very end' do
        @user = create :user
        @region2 = create :region
        @region3 = create :region
        create :call_list_entry, patient: @patient, user: @user, region: @region2
        create :call_list_entry, patient: create(:patient, region: @region3),
                                 user: @user,
                                 region: @region3

        assert_difference '@user.call_list_entries.where(region: @region2).count', -1 do
          assert_difference '@user.call_list_entries.where(region: @region3).count', 1 do
            @patient.update region: @region3
            @user.reload
          end
        end
        entry = @user.call_list_entries.where(patient: @patient, region: @region3).first
        assert_equal entry.order_key, 999
      end
    end
  end

  describe 'other methods' do
    before do
      @patient = create :patient, primary_phone: '111-222-3333',
                                  emergency_contact_phone: '111-222-4444',
                                  name: 'Yolo Goat Bart Simpson'
    end

    it 'primary_phone_display -- should be hyphenated phone' do
      assert_not_equal @patient.primary_phone, @patient.primary_phone_display
      assert_equal '111-222-3333', @patient.primary_phone_display
    end

    it 'secondary_phone_display - should be hyphenated other phone' do
      assert_not_equal @patient.emergency_contact_phone, @patient.emergency_contact_phone_display
      assert_equal '111-222-4444', @patient.emergency_contact_phone_display
    end

    it 'initials - creates proper initials' do
      assert_equal 'YGBS', @patient.initials
    end
  end

  describe 'concerns' do
    it 'should respond to history methods' do
      assert @patient.respond_to? :versions
      assert @patient.respond_to? :created_by
      assert @patient.respond_to? :created_by_id
    end
  end

  describe 'methods' do
    describe 'shareable concern methods' do
      describe 'shared_patients class method' do
        before do
          @region = create :region
          @region2 = create :region
          with_versioning do
            create :patient
            2.times { create :patient, shared_flag: true, region: @region }
            create :patient, shared_flag: true, region: @region2
          end
        end

        it 'should return shared patients by region' do
          assert_equal 2, Patient.shared_patients(@region).count
          assert_equal 1, Patient.shared_patients(@region2).count
        end
      end

      describe 'trim_shared_patients method' do
        it 'should trim shared patients after they have been inactive or resolved' do
          @patient.update shared_flag: true
          Patient.trim_shared_patients
          assert_not @patient.shared_flag
        end
      end

      describe 'still_shared? method' do
        describe 'without a custom shared_reset config' do
          it 'should return true if marked shared in last 6 days' do
            with_versioning do
              @patient.update shared_flag: true
              @patient.reload
            end
            assert @patient.still_shared?
          end

          it 'should return false if not updated for more than 6 days' do
            Timecop.freeze(Time.zone.now - 7.days) do
              with_versioning do
                @patient.update shared_flag: true
                @patient.reload
              end
            end

            assert_not @patient.still_shared?
          end
        end

        describe 'with a custom shared reset config' do
          before do
            c = Config.find_or_create_by(config_key: 'shared_reset')
            c.config_value = { options: ['14'] }
            c.save
          end

          after do
            Config.find_or_create_by(config_key: 'shared_reset').delete
          end

          it 'should return true if shared in the last configured days' do
            Timecop.freeze(Time.zone.now - 7.days) do
              with_versioning do
                @patient.update shared_flag: true
                @patient.reload
              end
            end

            assert @patient.still_shared?
          end

          it 'should return false if not updated in the last configured days' do
            Timecop.freeze(Time.zone.now - 15.days) do
              with_versioning do
                @patient.update shared_flag: true
                @patient.reload
              end
            end

            assert_not @patient.still_shared?
          end
        end
      end
    end

    describe 'saving identifier method' do
      it 'should return a identifier' do
        @patient.update primary_phone: '111-333-5555'
        assert_equal 'L3-5555', @patient.save_identifier
      end
    end

    describe 'most_recent_note_display_text method' do
      before do
        @note = @patient.notes.create full_text: (1..100).map(&:to_s).join('')
      end

      it 'returns 22 characters of the notes text' do
        assert_equal 22, @patient.most_recent_note_display_text.length
        assert_match /^1234/, @patient.most_recent_note_display_text
      end
    end

    describe 'destroy_associated_events method' do
      it 'should nuke associated events on patient destroy' do
        assert_difference 'Event.count', -1 do
          @patient.destroy_associated_events
        end
      end
    end

    describe 'archive_date method' do
      it 'should return a year if unaudited' do
        @patient.fulfillment.update audited: false
        assert_equal @patient.intake_date + 365.days, @patient.archive_date
      end
      it 'should return three months if audited' do
        @patient.fulfillment.update audited: true
        assert_equal @patient.intake_date + 90.days, @patient.archive_date
      end

      it 'should return custom audit config' do
        c = Config.find_or_create_by(config_key: 'days_to_keep_all_patients')
        c.config_value = { options: ['100'] }
        c.save

        c = Config.find_or_create_by(config_key: 'days_to_keep_fulfilled_patients')
        c.config_value = { options: ['300'] }
        c.save

        @patient.fulfillment.update audited: false
        assert_equal @patient.intake_date + 100.days, @patient.archive_date

        @patient.fulfillment.update audited: true
        assert_equal @patient.intake_date + 300.days, @patient.archive_date
      end
    end

    describe 'has_special_circumstances' do
      it 'should return false if there is an empty array' do
        @patient.update special_circumstances: []
        assert_equal @patient.has_special_circumstances, false
      end

      it 'should return false if there are no special circumstances' do
        @patient.update special_circumstances: [nil, nil]
        assert_equal @patient.has_special_circumstances, false
      end

      it 'should return true if there are special circumstances' do
        @patient.update special_circumstances: %w[special circumstances]
        assert_equal @patient.has_special_circumstances, true
      end

      it 'should return true if there are special circumstances and nils' do
        @patient.update special_circumstances: [nil, 'circumstances']
        assert_equal @patient.has_special_circumstances, true
      end
    end

    describe 'unconfirmed_practical_support' do
      before do
        # unconfirmed support, should show up
        @patient.practical_supports.create support_type: 'Companion',
                                           source: 'Cat',
                                           amount: 32,
                                           confirmed: false

        # confirmed support, should not show up
        @patient2.practical_supports.create support_type: 'Lodging',
                                            source: 'Org',
                                            amount: 100,
                                            confirmed: true

        # no practical support, also should not show up
        @patient3 = create :patient, emergency_contact_phone: '333-222-1111',
                                     emergency_contact: 'Cats',
                                     region: @region
      end

      context 'when a patient has unconfirmed supports' do
        it 'includes only the patient with unconfirmed support' do
          assert_includes Patient.unconfirmed_practical_support(@region), @patient
          assert_not_includes Patient.unconfirmed_practical_support(@region), @patient2
          assert_not_includes Patient.unconfirmed_practical_support(@region), @patient3
        end
      end

      context 'when supports are confirmed' do
        it 'no longer includes the patient' do
          @patient.practical_supports.each { |x| x.update confirmed: true }
          assert_empty Patient.unconfirmed_practical_support(@region)
        end
      end

      context 'when a patient has multiple supports' do
        before do
          @patient.practical_supports.first.update confirmed: false

          @patient.practical_supports.create support_type: 'Lodging',
                                             source: 'Org',
                                             amount: 200,
                                             confirmed: false
        end

        it 'should not return duplicates when multiple unconfirmed supports exist' do
          assert_no_difference 'Patient.unconfirmed_practical_support(@region).length' do
            @patient.practical_supports.create support_type: 'Travel to the region',
                                               source: 'Catbus',
                                               amount: 50,
                                               confirmed: false
          end
        end

        it 'returns the patient when some supports are confirmed' do
          assert_no_difference 'Patient.unconfirmed_practical_support(@region).length' do
            @patient.practical_supports.first.update confirmed: true
          end
        end

        it 'no longer returns the patient when all supports are confirmed' do
          assert_difference 'Patient.unconfirmed_practical_support(@region).length', -1 do
            @patient.practical_supports.each { |support| support.update confirmed: true }
          end
        end
      end
    end
  end

  describe 'all_versions' do
    before do
      # For some reason bullet doesn't play nicely with these unit tests,
      # but does with the system tests. Given the choice I prefer the system
      # tests, so we assume this is a false negative and turn off bullet for these.
      Bullet.enable = false
      with_versioning do
        @patient.update name: 'Cat Patient'
        @patient.practical_supports.create amount: 100, support_type: 'Cat petting', source: 'Catfund'
      end
    end

    after do
      Bullet.enable = true
    end

    it 'should not show fulfillment if not include_fulfillment' do
      version_types = @patient.all_versions(false).map(&:item_type).uniq
      assert_includes version_types, 'PracticalSupport'
      assert_includes version_types, 'Patient'
      assert_not_includes version_types, 'Fulfillment'
    end

    it 'should show fulfillment if include_fulfillment' do
      version_types = @patient.all_versions(true).map(&:item_type).uniq
      assert_includes version_types, 'PracticalSupport'
      assert_includes version_types, 'Patient'
      assert_includes version_types, 'Fulfillment'
    end
  end

  def patient_to_hash(patient)
    {
      id: patient.id,
      name: patient.name,
      procedure_date: patient.procedure_date
    }
  end
end
