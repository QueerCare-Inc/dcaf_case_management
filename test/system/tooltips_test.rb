require 'application_system_test_case'

# Confirm that the tooltip javascript actually pops up like we think it should
class TooltipsTest < ApplicationSystemTestCase
  before do
    @patient = create :patient
    @user = create :user
    log_in_as @user
  end

  describe 'an inline tooltip' do
    # Using call list as an example of this
    it 'should pop up with content' do
      visit authenticated_root_path

      within :css, '#call_list' do
        find('.daria-tooltip').hover
      end
      assert has_content? 'This sortable list is used'
    end
  end

  describe 'a checkbox label tooltip' do
    # Using resolved without assistance as an example of this
    it 'should pop up with content' do
      visit edit_patient_path(@patient)
      click_link 'Procedure Information'

      assert has_content? 'This is used to indicate that'
    end
  end
end
