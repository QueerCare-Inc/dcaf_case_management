require 'test_helper'

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  before do
    @user = create :user
    @region = create :region
    @patient = create :patient,
                      name: 'Susie Everyteen',
                      primary_phone: '123-456-7890',
                      emergency_contact_phone: '333-444-5555',
                      region: @region
    sign_in @user
    choose_region @region
  end

  describe 'index method' do
    before do
      get dashboard_path
    end

    it 'should return success' do
      assert_response :success
    end
  end

  describe 'search method' do
    it 'should return on name, primary phone, and emergency contact phone' do
      ['Susie Everyteen', '123-456-7890', '333-444-5555'].each do |searcher|
        post search_path, params: { search: searcher }, xhr: true
        assert_response :success
      end
    end
  end
end
