require 'application_system_test_case'

# Test workflows around administering lists of clinics a org works with
class ClinicManagementTest < ApplicationSystemTestCase
  before do
    create :region
    @clinic = create :clinic, accepts_medicaid: true

    @user = create :user, role: 'admin'
    @nonadmin = create :user, role: 'care_coordinator'
    log_in_as @user
    visit clinics_path
  end

  describe 'viewing clinic info' do
    before { visit clinics_path }

    it 'should have existing clinics in the table' do
      within :css, '#clinics_table' do
        assert has_text? @clinic.name
      end
    end
  end

  describe 'adding a clinic' do
    before { click_on 'Add a new clinic' }

    it 'should add a clinic' do
      new_clinic_name = fill_in_all_clinic_fields
      click_on 'Add clinic'

      assert has_text? "#{new_clinic_name} created!"
      within :css, '#clinics_table' do
        assert has_text? new_clinic_name
      end
      click_on new_clinic_name

      assert_fields_have_proper_content
    end

    it 'should prevent creation if the payload is bad' do
      invalid_clinic_name = 'Just the name, no other required fields'
      fill_in 'Name', with: invalid_clinic_name
      click_button 'Add clinic'

      assert_not has_link? 'Add a new clinic'
      assert has_text? 'Errors prevented this clinic from being saved'
    end
  end

  describe 'updating a clinic' do
    before { visit edit_clinic_path(@clinic) }

    it 'should let you update a clinic' do
      new_clinic_name = fill_in_all_clinic_fields
      click_button 'Save changes'

      assert has_text? 'Successfully updated clinic details'
      within :css, '#clinics_table' do
        assert has_text? new_clinic_name
      end
      click_link new_clinic_name

      assert_fields_have_proper_content
    end

    it 'should prevent updates if the payload is bad' do
      fill_in 'Name', with: ''
      click_button 'Save changes'
      assert has_text? 'Edit clinic details'
      assert has_text? 'Error saving clinic details'
    end
  end

  describe 'disabling a clinic' do
    before { @patient = create :patient }

    it 'should partition itself from the active clinics list when disabled' do
      visit edit_clinic_path @clinic
      uncheck 'Are we actively working with this clinic?'
      click_button 'Save changes'

      visit edit_patient_path @patient
      click_link 'Procedure Information'
      select "(Not currently working with CATF) - #{@clinic.name}", from: 'patient_clinic_id'
      assert_equal @clinic.id.to_s, find('#patient_clinic_id').value
    end
  end

  private

  def fill_in_all_clinic_fields
    new_clinic_name = 'Games Done Quick Throw a Benefit for Abortion Orgs'
    fill_in 'Name', with: new_clinic_name
    fill_in 'Street address', with: '123 Fake Street'
    fill_in 'City', with: 'Yolo'
    select 'TX', from: 'clinic_state'
    fill_in 'ZIP', with: '12345'
    fill_in 'Phone', with: '281-330-8004'
    fill_in 'Fax', with: '222-333-4444'
    check 'Accepts NAF'
    check 'Accepts Medicaid'
    new_clinic_name
  end

  def assert_fields_have_proper_content
    assert has_field? 'Name', with: 'Games Done Quick Throw a Benefit for Abortion Orgs'
    assert has_field? 'Street address', with: '123 Fake Street'
    assert has_field? 'City', with: 'Yolo'
    assert_equal 'TX', find('#clinic_state').value
    assert has_field? 'ZIP', with: '12345'
    assert has_field? 'Phone', with: '281-330-8004'
    assert has_field? 'Fax', with: '222-333-4444'
    assert has_checked_field? 'Accepts NAF'
    assert has_checked_field? 'Accepts Medicaid'
  end
end
