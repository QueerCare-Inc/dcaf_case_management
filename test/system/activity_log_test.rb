require 'application_system_test_case'

# Confirm that calls and pledges are showing up in activity log
class ActivityLogTest < ApplicationSystemTestCase
  before do
    @user = create :user
    @clinic = create :clinic
    @region = create :region
    @patient = create :patient,
                      clinic: @clinic,
                      procedure_date: 3.days.from_now,
                      region: @region

    log_in_as @user, @region
    visit edit_patient_path @patient
  end

  describe 'logging phone calls' do
    it 'should log a phone call into the activity log' do
      wait_for_element 'Call Log'
      click_link 'Call Log'
      click_link 'Record new call'
      wait_for_element 'I left a voicemail for the patient'
      click_link 'I left a voicemail for the patient'
      wait_for_ajax

      visit authenticated_root_path
      wait_for_css '#activity_log_content'
      wait_for_css '#event-item'
      wait_for_ajax
      wait_for_no_css '.sk-spinner'

      within :css, '#activity_log_content' do
        assert has_content? "#{@user.name} left a voicemail for " \
                            "#{@patient.name}"
      end
    end
  end
end
