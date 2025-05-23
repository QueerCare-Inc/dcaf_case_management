require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Since this is a devise install, devise is handling
  # general stuff like creation timestamps etc.
  before { @user = create :user }

  describe 'basic validations' do
    it 'should be able to build an object' do
      assert @user.valid?
    end

    %w[email name].each do |attribute|
      it "should require content in #{attribute}" do
        @user[attribute.to_sym] = nil
        assert_not @user.valid?
        assert_equal "can't be blank",
                     @user.errors.messages[attribute.to_sym].first
      end
    end

    it 'should require a complex password' do
      @user.password = 'password'
      @user.password_confirmation = 'password'
      assert_not @user.valid?
      assert_equal 'Password must include at least one lowercase letter, ' \
                   'one uppercase letter, and one digit. Forbidden words ' \
                   'include CATF and password.',
                   @user.errors.messages[:password].first
    end

    it 'should require a strong password' do
      @user.password = 'Hello#2020'
      @user.password_confirmation = 'Hello#2020'
      assert_not @user.valid?
      assert_equal 'Passwords need to be stronger than that. ' \
                   'Try a longer or more complicated password please.',
                   @user.errors.messages[:password].first
    end

    it 'should not allow the name of the org' do
      @user.password = 'AbortionsAreAHumanRight1CATF'
      @user.password_confirmation = 'AbortionsAreAHumanRight1CATF'
      assert_not @user.valid?
      assert_equal 'Password must include at least one lowercase letter, ' \
                   'one uppercase letter, and one digit. Forbidden words ' \
                   'include CATF and password.',
                   @user.errors.messages[:password].first
    end

    it 'should allow a strong password' do
      @user.password = 'AbortionsAreAHumanRight1'
      @user.password_confirmation = 'AbortionsAreAHumanRight1'
      assert @user.valid?
    end
  end

  describe 'call list methods' do
    before do
      @region = create :region
      @region2 = create :region
      @patient = create :patient, region: @region
      @patient_2 = create :patient, region: @region
      @md_patient = create :patient, region: @region2
      @user.add_patient @patient
      @user.add_patient @patient_2
      @user.add_patient @md_patient
      @user_2 = create :user
    end

    it 'should return recently_called_patients accurately' do
      assert_equal 0, @user.recently_called_patients(@region).count

      with_versioning(@user) do
        @patient.calls.create attributes_for(:call)
        @patient_2.calls.create attributes_for(:call)
        @md_patient.calls.create attributes_for(:call)
      end

      assert_equal 2, @user.recently_called_patients(@region).count
      assert_equal 1, @user.recently_called_patients(@region2).count
    end

    it 'should return call_list_patients accurately' do
      assert_equal 2, @user.call_list_patients(@region).count
      assert_equal 1, @user.call_list_patients(@region2).count

      with_versioning(@user) do
        @patient.calls.create attributes_for(:call)
      end
      assert_equal 1, @user.call_list_patients(@region).count

      with_versioning(create(:user)) do
        @patient_2.calls.create attributes_for(:call)
      end
      assert_equal 1, @user.call_list_patients(@region).count
    end

    it 'should clean calls when patient has been reached' do
      assert_equal 0, @user.recently_called_patients(@region).count

      with_versioning(@user) do
        @patient.calls.create attributes_for(:call, status: :reached_patient)
      end
      @call = @patient.calls.first
      assert_equal 1, @user.recently_called_patients(@region).count
      assert_difference '@user.recently_called_patients(@region).count', -1 do
        @user.clean_call_list_between_shifts
      end
    end

    it 'should not clear calls when patient has not been reached' do
      assert_equal 0, @user.recently_called_patients(@region).count

      with_versioning(@user) do
        @patient.calls.create attributes_for(:call, status: :left_voicemail)
      end
      @call = @patient.calls.first
      assert_equal 1, @user.recently_called_patients(@region).count
      @user.clean_call_list_between_shifts
      assert_equal 1, @user.recently_called_patients(@region).count
    end

    it 'should clear patient list when user has not logged in' do
      assert_not @user.call_list_entries.empty?
      last_sign_in = Time.zone.now - User::TIME_BEFORE_INACTIVE - 1.day
      @user.update current_sign_in_at: last_sign_in
      @user.clean_call_list_between_shifts

      assert @user.call_list_entries.empty?
    end

    it 'should not clear patient list if user signed in recently' do
      assert_not @user.call_list_entries.empty?
      @user.current_sign_in_at = Time.zone.now
      @user.clean_call_list_between_shifts

      assert_not @user.call_list_entries.empty?
    end

    it 'should clear call list when someone invokes the cleanout' do
      assert_difference '@user.call_list_entries.count', -2 do
        assert_no_difference '@user.call_list_entries.where(region: @region2).count' do
          assert_no_difference 'Patient.count' do
            @user.clear_call_list @region
          end
        end
      end
    end
  end

  describe 'patient methods' do
    before do
      @region = create :region
      @region2 = create :region
      @patient = create :patient, region: @region2
      @patient_2 = create :patient, region: @region
      @patient_3 = create :patient, region: @region
    end

    it 'add patient - should add a patient to a set' do
      assert_difference '@user.call_list_entries.count', 1 do
        @user.add_patient @patient
      end
    end

    it 'remove patient - should remove a patient from a set' do
      @user.add_patient @patient
      assert_difference '@user.call_list_entries.count', -1 do
        @user.remove_patient @patient
      end
    end

    describe 'reorder call list' do
      before do
        [@patient, @patient_2, @patient_3].each { |patient| @user.add_patient patient }
        new_order = [@patient_3, @patient_2].map { |x| x.id.to_s }
        @user.reorder_call_list new_order, @region
      end

      it 'should let you reorder a call list' do
        assert_equal @patient_3, @user.call_list_patients(@region).first
        assert_equal @patient_2, @user.call_list_patients(@region)[1]
      end

      it 'should always add new patients to the front of the call order' do
        @patient_4 = create :patient, region: @region
        @user.add_patient @patient_4

        assert @user.call_list_patients(@region).include? @patient_4
        assert_equal @user.call_list_patients(@region).map { |x| x.id.to_s }.index(@patient_4.id.to_s), 0
      end
    end
  end

  describe 'relationships' do
    before do
      @patient = create :patient
      @patient_2 = create :patient
      @user.add_patient @patient
      @user.add_patient @patient_2
      @user_2 = create :user
    end

    it 'should have any belong to many patients' do
      [@patient, @patient_2].each do |preg|
        [@user, @user_2].each { |user| user.add_patient preg }
      end

      assert_equal @user.call_list_entries.pluck(:patient_id, :region_id, :order_key),
                   @user_2.call_list_entries.pluck(:patient_id, :region_id, :order_key)
    end
  end

  describe 'omniauthing' do
    before do
      @token = OpenStruct.new info: { 'email' => @user.email }
    end

    it 'should return a user from an access token' do
      assert_equal @user, User.from_omniauth(@token)
    end

    it 'should error on no user' do
      @user.destroy
      assert_raises ActiveRecord::RecordNotFound do
        User.from_omniauth(@token)
      end
    end
  end

  describe 'data access' do
    it 'should allow for admins' do
      assert create(:user, role: :admin).allowed_data_access?
    end

    it 'should allow for data volunteers' do
      assert create(:user, role: :data_volunteer).allowed_data_access?
    end

    it 'should allow for finance admins' do
      assert create(:user, role: :finance_admin).allowed_data_access?
    end

    it 'should allow for care coordination admins' do
      assert create(:user, role: :coord_admin).allowed_data_access?
    end

    it 'should not allow for care coordinators' do
      assert_not create(:user, role: :care_coordinator).allowed_data_access?
    end

    it 'should not allow for CRs' do
      assert_not create(:user, role: :cr).allowed_data_access?
    end

    it 'should not allow for volunteers' do
      assert_not create(:user, role: :volunteer).allowed_data_access?
    end
  end

  describe 'manual account shutoff (disabled_by_org)' do
    before { @user = create :user }
    it 'should default to enabled' do
      assert_not @user.disabled_by_org?
    end

    it 'is toggleable' do
      @user.toggle_disabled_by_org
      @user.reload
      assert @user.disabled_by_org
    end

    it 'resets the current sign in token only on reenable' do
      assert_nil @user.current_sign_in_at
      @user.toggle_disabled_by_org
      @user.reload
      assert_nil @user.current_sign_in_at

      @user.toggle_disabled_by_org
      @user.reload
      assert_not_nil @user.current_sign_in_at
    end

    describe 'nightly cleanup task - disable_inactive_users' do
      before do
        @disabled_user = create(:user, current_sign_in_at: 10.months.ago)
        @admin = create(:user, role: :admin, current_sign_in_at: 11.months.ago)
        @no_login_user = create(:user, created_at: 12.months.ago)
        @nondisabled_user = create(:user, current_sign_in_at: 8.months.ago)
        User.disable_inactive_users
      end

      it 'should find inactive users with logins before cutoff and disable' do
        # disabled and no-login should be shut off
        assert @disabled_user.reload.disabled_by_org?
        assert @no_login_user.reload.disabled_by_org?

        # No locking admins or users with recent activity
        assert_not @admin.disabled_by_org?
        assert_not @nondisabled_user.disabled_by_org?
      end
    end
  end
end
