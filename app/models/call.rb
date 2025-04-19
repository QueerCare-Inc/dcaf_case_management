# Object representing a case manager dialing a patient.
class Call < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include EventLoggable
  include PaperTrailable

  # Enums
  enum :status, {
    reached_patient: 0,
    left_voicemail: 1,
    couldnt_reach_patient: 2
  }

  # Relationships
  belongs_to :can_call, polymorphic: true

  # Validations
  validates :status, presence: true

  # Methods
  def recent?
    updated_at > 8.hours.ago
  end

  # TODO: revisit this relationship between user, care coordinator, and patient
  def event_params
    # user = User.find_by(id: PaperTrail&.request&.whodunnit)
    # patient_user = User.find_by!(id: can_call.user_id)

    patient_user = User.find(can_call.user_id)
    {
      event_type: status.to_s,
      # care_coordinator_name: user&.name || 'System',
      patient_name: patient_user.name,
      patient_id: can_call.id,
      region_id: patient_user.region_id
      # region: can_call.region
    }
  end
end
