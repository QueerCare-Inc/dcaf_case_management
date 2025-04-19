require 'application_system_test_case'

# Test that the buttons to change user roles work
class ChangeUserRolesTest < ApplicationSystemTestCase
  before do
    create :region
    @user = create :user, role: 'admin', name: 'Billy'
    @user2 = create :user, role: 'care_coordinator', name: 'Susie'
    log_in_as @user
  end

  describe 'changing a user role' do
    it 'should let you swap roles back and forth' do
      visit edit_user_path @user2
      click_link "Change Susie's role to Admin"
      assert has_content? 'Role: admin'

      click_link "Change Susie's role to Data Volunteer"
      assert has_content? 'Role: data_volunteer'

      click_link "Change Susie's role to Care_coordinator"
      assert has_content? 'Role: care_coordinator'
    end
  end

  describe 'trying to change your own role' do
    it 'should not show you the options to do that' do
      visit edit_user_path @user
      assert_not has_content? "Change Billy's role to Data Volunteer"
    end
  end
end
