require "test_helper"

class RegionTest < ActiveSupport::TestCase
  before { @region = create :region }

  describe 'validations' do
    it 'should build' do
      assert create(:region).valid?
    end

    [:name].each do |attrib|
      it "should require #{attrib}" do
        @region[attrib] = nil
        refute @region.valid?
      end
    end

    it 'should be unique on name within a fund' do
      create :region, name: 'DC'
      region2 = create :region
      assert region2.valid?
      region2.name = 'DC'
      refute region2.valid?

      ActsAsTenant.with_tenant(create(:fund)) do
        region3 = create :region, name: 'DC'
        assert region3.valid?
      end
    end
  end
end
