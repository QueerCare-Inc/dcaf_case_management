require 'test_helper'

class NavbarHelperTest < ActionView::TestCase
  include ERB::Util

  describe 'care_coordinator_resources_link' do
    before do
      @config = create :config, config_key: 'resources_url',
                                config_value: { options: ['http://www.google.com'] }
    end

    it 'should return nil if config is not set' do
      @config.update config_value: { options: [] }
      assert_not care_coordinator_resources_link
    end

    it 'should return a link if config set' do
      expected_link = '<li><a target="_blank" class="nav-link" href="https://www.google.com">Care Coordinator Resources</a></li>'
      assert_equal expected_link, care_coordinator_resources_link
    end
  end
end
