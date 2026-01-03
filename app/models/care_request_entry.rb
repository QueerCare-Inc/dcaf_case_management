# Object representing a care coordinate list.
class CareRequestEntry < ApplicationRecord
  acts_as_tenant :org

  include Statusable

  # Relationships
  belongs_to :region
  belongs_to :procedure
  belongs_to :patient
  belongs_to :care_coordinator, class_name: 'User', optional: true

  # # Validations
  validates :region, presence: true
  validates_uniqueness_to_tenant :procedure, scope: :patient
  # TODO: revisit this last line. I'm not certain this is the correct translation.

  validates :procedure, presence: true
  validates :patient, presence: true

  def self.create_care_request_entry(patient:, procedure:, region:, care_coordinator: nil)
    create(
      care_coordinator: care_coordinator,
      patient: patient,
      procedure: procedure,
      region: region
    )
  end

  def self.find_or_create_care_request_entry(patient:, procedure:, region:, care_coordinator: nil)
    find_or_create_by(
      care_coordinator: care_coordinator,
      patient: patient,
      procedure: procedure,
      region: region
    )
  end

  def update_care_request_entry(attributes)
    update(attributes)
  end

  def remove_care_request_entry
    destroy
  end

  def self.remove_shift_entry_by_id(care_request_entry_id)
    find(care_request_entry_id).destroy
  end

  private
end
