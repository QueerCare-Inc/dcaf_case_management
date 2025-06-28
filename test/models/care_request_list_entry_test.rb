require 'test_helper'

class CareRequestListEntryTest < ActiveSupport::TestCase
  before do
    @care_request_list_entry = create :care_request_list_entry
  end

  describe 'validations' do
    it 'should be able to build an object' do
      assert @care_request_list_entry.valid?
    end

    %i(order_key).each do |field|
      it "should enforce presence of #{field}" do
        @care_request_list_entry[field] = nil
        refute @care_request_list_entry.valid?
      end
    end

    it 'should have a unique patient_id by user' do
      care_request_list_pt = @care_request_list_entry.patient_id
      care_request_list_user = @care_request_list_entry.user_id

      entry = build :care_request_list_entry, patient_id: care_request_list_pt,
                                      user_id: care_request_list_user
      refute entry.valid?
      assert_equal 'Patient has already been taken',
                   entry.errors.full_messages.first

      entry.user = create :user
      assert entry.valid?
    end
  end
end
