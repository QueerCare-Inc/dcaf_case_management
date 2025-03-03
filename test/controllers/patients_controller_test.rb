require 'test_helper'

class PatientsControllerTest < ActionDispatch::IntegrationTest
  before do
    @user = create :user
    @admin = create :user, role: :admin
    @region = create :region
    @data_volunteer = create :user, role: :data_volunteer

    sign_in @user
    choose_region @region
    @clinic = create :clinic
    @patient = create :patient,
                      name: 'Susie Everyteen',
                      primary_phone: '123-456-7890',
                      other_phone: '333-444-5555',
                      region: @region,
                      city: '=injected_formula'
    @archived_patient = create :archived_patient,
                               region: @region,
                               intake_date: 400.days.ago
  end

  describe 'index method' do
    before do
      # Not sure if there is a better way to do this, but just calling
      # `sign_in` a second time doesn't work as expected
      delete destroy_user_session_path
    end

    it 'should reject users without access' do
      sign_in @user

      get patients_path
      assert_redirected_to root_path

      get patients_path(format: :csv)
      assert_redirected_to root_path
    end

    it 'should not serve html' do
      sign_in @data_volunteer
      get patients_path
      assert_equal response.status, 406
    end

    it 'should get csv when user is admin' do
      sign_in @admin
      get patients_path(format: :csv)
      assert_response :success
    end

    it 'should get csv when user is data volunteer' do
      sign_in @data_volunteer
      get patients_path(format: :csv)
      assert_response :success
    end

    it 'should use proper mimetype' do
      sign_in @data_volunteer
      get patients_path(format: :csv)
      assert_equal 'text/csv', response.content_type.split(';').first
    end

    it 'should consist of a header region, the patient record, and the archived patient record' do
      sign_in @data_volunteer
      get patients_path(format: :csv)
      regions = response.body.split("\n").reject(&:blank?)
      assert_equal 3, regions.count
      assert_match @patient.id.to_s, regions[1]
      assert_match @archived_patient.id.to_s, regions[2]
    end

    it 'should not contain personally-identifying information' do
      sign_in @data_volunteer
      get patients_path(format: :csv)
      assert_no_match @patient.name.to_s, response.body
      assert_no_match @patient.primary_phone.to_s, response.body
      assert_no_match @patient.other_phone.to_s, response.body
    end

    it 'should escape fields with attempted formula injection' do
      sign_in @data_volunteer
      get patients_path(format: :csv)
      regions = response.body.split("\n").reject(&:blank?)
      # A single quote at the beginning indicates it's escaped.
      assert_match "'=injected_formula", regions[1]
    end
  end

  describe 'create method' do
    before do
      @new_patient = attributes_for :patient, name: 'Test Patient', region_id: @region.id
    end

    it 'should create and save a new patient' do
      assert_difference 'Patient.count', 1 do
        post patients_path, params: { patient: @new_patient }
      end
    end

    it 'should redirect to the root path afterwards' do
      post patients_path, params: { patient: @new_patient }
      assert_redirected_to root_path
    end

    it 'should fail to save if name is blank' do
      @new_patient[:name] = ''
      assert_no_difference 'Patient.count' do
        post patients_path, params: { patient: @new_patient }
      end
    end

    it 'should fail to save if primary phone is blank' do
      @new_patient[:primary_phone] = ''
      assert_no_difference 'Patient.count' do
        post patients_path, params: { patient: @new_patient }
      end
    end

    it 'should create an associated fulfillment object' do
      post patients_path, params: { patient: @new_patient }
      assert_not_nil Patient.find_by(name: 'Test Patient').fulfillment
    end
  end

  describe 'edit method' do
    before do
      get edit_patient_path(@patient)
    end

    it 'should get edit' do
      assert_response :success
    end

    it 'should redirect to root on a bad id' do
      get edit_patient_path('notanid')
      assert_redirected_to root_path
    end

    it 'should contain the current record' do
      assert_match /Susie Everyteen/, response.body
      assert_match /123-456-7890/, response.body
      assert_match /Friendly Clinic/, response.body
    end
  end

  describe 'update method' do
    describe 'as HTML' do
      before do
        @date = 5.days.from_now.to_date
        @payload = {
          appointment_date: @date.strftime('%Y-%m-%d'),
          name: 'Susie Everyteen 2',
          clinic_id: @clinic.id
        }

        patch patient_path(@patient), params: { patient: @payload }, xhr: true
        @patient.reload
      end

      it 'should update last edited by' do
        assert_equal @user, @patient.last_edited_by
      end

      it 'should respond success on completion' do
        patch patient_path(@patient), params: { patient: @payload }, xhr: true
        assert response.body.include? 'saved'
      end

      it 'should respond not acceptable error on failure' do
        @payload[:primary_phone] = nil
        patch patient_path(@patient), params: { patient: @payload }, xhr: true
        assert response.body.include? 'alert alert-danger'
      end

      it 'should update patient fields' do
        assert_equal 'Susie Everyteen 2', @patient.name
      end

      it 'should redirect if record does not exist' do
        patch patient_path('notanactualid'), params: { patient: @payload }
        assert_redirected_to root_path
      end
    end

    describe 'as JSON' do
      before do
        @date = 5.days.from_now.to_date
        @payload = {
          appointment_date: @date.strftime('%Y-%m-%d'),
          name: 'Susie Everyteen 2',
          clinic_id: @clinic.id
        }

        patch patient_path(@patient), params: { patient: @payload }, as: :json
        @patient.reload
      end

      it 'should update last edited by' do
        assert_equal @user, @patient.last_edited_by
      end

      it 'should respond success on completion' do
        patch patient_path(@patient), params: { patient: @payload }, as: :json
        assert_not_nil JSON.parse(response.body)['patient']
      end

      it 'should respond not acceptable error on failure' do
        @payload[:primary_phone] = nil
        patch patient_path(@patient), params: { patient: @payload }, as: :json
        assert_not_nil JSON.parse(response.body)['flash']['alert']
      end

      it 'should update patient fields' do
        assert_equal 'Susie Everyteen 2', @patient.name
      end

      it 'should redirect if record does not exist' do
        patch patient_path('notanactualid'), params: { patient: @payload }
        assert_redirected_to root_path
      end
    end
  end

  describe 'data_entry method' do
    it 'should respond success on completion' do
      get data_entry_path
      assert_response :success
    end
  end

  # confirm sending a 'post' with a payload results in a new patient
  describe 'data_entry_create method' do
    before do
      @test_patient = attributes_for :patient, name: 'Test Patient', region_id: create(:region).id
    end

    it 'should create and save a new patient' do
      assert_difference 'Patient.count', 1 do
        post data_entry_create_path, params: { patient: @test_patient }
      end
    end

    it 'should redirect to edit_patient_path afterwards' do
      post data_entry_create_path, params: { patient: @test_patient }
      @created_patient = Patient.find_by(name: 'Test Patient')
      assert_redirected_to edit_patient_path @created_patient
    end

    it 'should fail to save if name is blank' do
      @test_patient[:name] = ''
      assert_no_difference 'Patient.count' do
        post data_entry_create_path, params: { patient: @test_patient }
      end
    end

    it 'should fail to save if primary phone is blank' do
      @test_patient[:primary_phone] = ''
      assert_no_difference 'Patient.count' do
        post data_entry_create_path, params: { patient: @test_patient }
        assert_response :success
      end
    end

    it 'should create an associated fulfillment object' do
      post data_entry_create_path, params: { patient: @test_patient }
      assert_not_nil Patient.find_by(name: 'Test Patient').fulfillment
    end

    it 'should fail to save if initial call date is nil' do
      @test_patient[:intake_date] = nil
      @test_patient[:appointment_date] = Date.tomorrow
      assert_no_difference 'Patient.count' do
        post data_entry_create_path, params: { patient: @test_patient }
        assert_response :success
      end
    end
  end

  describe 'destroy' do
    describe 'authorization' do
      it 'should allow admins only' do
        [@user, @data_volunteer].each do |user|
          delete destroy_user_session_path
          sign_in @user

          assert_no_difference 'Patient.count' do
            delete patient_path(@patient)
          end
          assert_redirected_to root_url
        end
      end
    end

    describe 'behavior' do
      before do
        delete destroy_user_session_path
        sign_in @admin
      end

      it 'should destroy a patient' do
        assert_difference 'Patient.count', -1 do
          delete patient_path(@patient)
        end
        assert_not_nil flash[:notice]
      end

      it 'should prevent a patient from being destroyed under some circumstances' do
        @patient.update appointment_date: 2.days.from_now,
                        clinic: (create :clinic)

        assert_no_difference 'Patient.count' do
          delete patient_path(@patient)
        end
        assert_not_nil flash[:alert]
      end
    end
  end
end
