require 'test_helper'

class RegionsHelperTest < ActionView::TestCase
  include ERB::Util

  describe 'convenience methods' do
    it 'should return empty if not set' do
      assert_nil current_region
      assert_nil current_region_display
    end

    it 'should show a link if 2+ regions' do
      @regions = [
        create(:region, name: 'DC'),
        create(:region, name: 'MD'),
        create(:region, name: 'VA')
      ]

      @regions.each do |region|
        session[:region_id] = region.id
        session[:region_name] = region.name
        assert_equal current_region_display,
                     "<li><a class=\"nav-link navbar-text-alt\" href=\"/regions/new\">Your current region: #{session[:region_name]}</a></li>"
        assert_equal current_region, region
      end
    end

    it 'should show text if just one region' do
      region = create(:region, name: 'DC')
      session[:region_id] = region.id
      session[:region_name] = region.name
      assert_equal current_region_display,
                    "<li><span class=\"nav-link navbar-text-alt\">Your current region: #{session[:region_name]}</span></li>"
      assert_equal current_region, region
    end
  end
end
