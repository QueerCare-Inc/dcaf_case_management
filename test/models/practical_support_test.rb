require 'test_helper'

class PracticalSupportTest < ActiveSupport::TestCase
  before do
    @user = create :user
    @patient = create :patient
    @patient.practical_supports.create support_type: 'Concert Tickets',
                                       source: 'Metallica Abortion Org'
    @patient.practical_supports.create support_type: 'Swag',
                                       source: 'YOLO AF',
                                       confirmed: true,
                                       start_time: 2.days.from_now,
                                       end_time: 3.days.from_now
    @patient.practical_supports.create support_type: 'Companion',
                                       source: 'Cat',
                                       amount: 32
    @psupport1 = @patient.practical_supports.first
    @psupport2 = @patient.practical_supports.second
    @psupport3 = @patient.practical_supports.last
  end

  describe 'concerns' do
    it 'should respond to history methods' do
      assert @psupport1.respond_to? :versions
      assert @psupport1.respond_to? :created_by
      assert @psupport1.respond_to? :created_by_id
    end

    describe 'most_recent_note_display_text' do
      before do
        @note = @psupport1.notes.create full_text: (1..100).map(&:to_s).join('')
      end

      it 'returns 22 characters of the notes text' do
        assert_equal 22, @psupport1.most_recent_note_display_text.length
        assert_match /^1234/, @psupport1.most_recent_note_display_text
      end
    end
  end

  describe 'validations' do
    # NOTE: amount is not required
    [:source, :support_type].each do |field|
      it "should enforce presence of #{field}" do
        @psupport1[field.to_sym] = nil
        assert_not @psupport1.valid?
      end
    end
  end
end
