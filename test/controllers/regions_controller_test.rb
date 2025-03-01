require 'test_helper'

# Test regions setting behavior
class RegionsControllerTest < ActionDispatch::IntegrationTest
  before do
    @user = create :user
    @region = create :region
    sign_in @user
  end

  describe 'new' do
    describe 'instance with multiple regions' do
      # Stub a second region
      before { create :region }

      it 'should return success' do
        get new_region_path
        assert_response :success
      end
    end

    describe 'instance with one region' do
      it 'should redirect to patient dashboard' do
        get new_region_path
        assert_redirected_to authenticated_root_path
        assert_equal @region.id, session[:region_id]
      end
    end

    describe 'instance with no regions' do
      it 'should raise an error' do
        @region.destroy
        get new_region_path
        assert_equal response.status, 500
      end
    end
  end

  describe 'create' do
    before do
      post regions_path, params: { region_id: @region.id }
    end

    it 'should set a session variable' do
      assert_equal @region.id, session[:region_id]
    end

    # TODO: Enforce region values
    # it 'should reject anything not set in regions' do
    # end
  end
end
