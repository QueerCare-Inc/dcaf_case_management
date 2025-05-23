require 'application_system_test_case'

# Testing around call list table content
class TableContentTest < ApplicationSystemTestCase
  # problematic test
  before do
    @user = create :user
    @patient = create :patient, intake_date: 3.days.ago,
                                procedure_date: 3.days.from_now.utc,
                                shared_flag: true

    @patient.calls.create status: :left_voicemail,
                          created_at: 3.days.ago,
                          updated_at: 3.days.ago

    @user.add_patient @patient
    log_in_as @user
    wait_for_element 'Build your call list'
  end

  describe 'visiting the dashboard' do
    it 'should display attributes in call list table' do
      within :css, '#call_list_content' do
        assert has_content? @patient.primary_phone_display
        assert has_content? @patient.name
        assert has_content? 3.days.from_now.utc.strftime('%m/%d/%Y')
        # TODO: has remove, phone clicky
      end
    end
  end
end
