require 'test_helper'

class RegionTest < ActiveSupport::TestCase
  before { @region = create :region }

  describe 'validations' do
    it 'should build' do
      assert create(:region).valid?
    end

    [:name].each do |attrib|
      it "should require #{attrib}" do
        @region[attrib] = nil
        assert_not @region.valid?
      end
    end

    it 'should be unique on name within a org' do
      create :region, name: 'DC'
      region2 = create :region
      assert region2.valid?
      region2.name = 'DC'
      assert_not region2.valid?

      ActsAsTenant.with_tenant(create(:org)) do
        region3 = create :region, name: 'DC'
        assert region3.valid?
      end
    end
  end
end
