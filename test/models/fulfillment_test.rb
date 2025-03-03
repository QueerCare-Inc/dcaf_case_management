require 'test_helper'

class FulfillmentTest < ActiveSupport::TestCase
  before do
    @user = create :user
    @pt_1 = create :patient, name: 'Susan Smith'
    @fulfillment = @pt_1.fulfillment
  end

  describe 'concerns' do
    it 'should respond to history methods' do
      assert @fulfillment.respond_to? :versions
      assert @fulfillment.respond_to? :created_by
      assert @fulfillment.respond_to? :created_by_id
    end
  end
end
