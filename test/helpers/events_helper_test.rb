require 'test_helper'

class EventsHelperTest < ActionView::TestCase
  describe 'fontawesome_classes' do
    it 'should kit properly' do
      event = create :event, event_type: :left_voicemail
      assert_equal 'fas fa-phone-alt', fontawesome_classes(event)
    end
  end
end
