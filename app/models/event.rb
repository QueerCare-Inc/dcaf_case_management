# Object representing relevant actions taken by a case manager.
class Event < ApplicationRecord
  acts_as_tenant :org

  # Relations
  belongs_to :region

  # encrypts :care_coordinator_name
  encrypts :patient_name

  # Enums
  enum :event_type, {
    reached_patient: 0,
    couldnt_reach_patient: 1,
    left_voicemail: 2,
    pledged: 3,
    unknown_action: 4
  }
  # TODO: what other actions do we want to add?

  # Validations
  validates :event_type, :patient_name, :patient_id, :region_id, presence: true # :care_coordinator_name,

  def icon
    case event_type
    when 'reached_patient'
      'comment'
    else
      'phone-alt'
    end
  end

  # Clean events older than three weeks
  def self.destroy_old_events
    Event.where('created_at < ?', 3.weeks.ago)
         .destroy_all
  end
end
