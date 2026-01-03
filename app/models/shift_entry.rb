class ShiftEntry < ApplicationRecord
  before_destroy :delete_shift_if_last_entry

  belongs_to :org
  belongs_to :region
  belongs_to :care_coordinator, optional: true
  belongs_to :patient
  belongs_to :volunteer, optional: true
  belongs_to :procedure
  belongs_to :care_address
  belongs_to :shift

  validates :shift, presence: true
  validates :procedure, presence: true
  validates :patient, presence: true
  validate :shift_procedure_patient_uniqueness
  validate :must_have_procedure
  validate :must_have_care_address
  validate :must_have_shift

  # Create a new shift entry
  def self.create_shift_entry(care_coordinator:, patient:, volunteer:, procedure:, care_address:, shift:)
    create(
      care_coordinator: care_coordinator,
      patient: patient,
      volunteer: volunteer,
      procedure: procedure,
      care_address: care_address,
      shift: shift
    )
  end

  # Find or create a shift entry
  def self.find_or_create_shift_entry(care_coordinator:, patient:, volunteer:, procedure:, care_address:, shift:)
    find_or_create_by(
      care_coordinator: care_coordinator,
      patient: patient,
      volunteer: volunteer,
      procedure: procedure,
      care_address: care_address,
      shift: shift
    )
  end

  # Update specific attributes of a shift entry
  def update_shift_entry(attributes)
    update(attributes)
  end

  # Remove a shift entry
  def remove_shift_entry
    destroy
  end

  # Remove a shift entry by ID
  def self.remove_shift_entry_by_id(shift_entry_id)
    find(shift_entry_id).destroy
  end

  private

  def shift_procedure_patient_uniqueness
    return unless ShiftEntry.exists?(shift: shift, procedure: procedure, patient: patient)

    errors.add(:base, 'This shift is already assigned to the volunteer.')
  end

  def must_have_procedure
    errors.add(:procedure, I18n.t('errors.shift_entry.must_have_procedure')) unless procedure.present?
  end

  def must_have_care_address
    errors.add(:care_address, I18n.t('errors.shift_entry.must_have_care_address')) unless care_address.present?
  end

  def must_have_shift
    errors.add(:shift, I18n.t('errors.shift_entry.must_have_shift')) unless shift.present?
  end

  def delete_shift_if_last_entry
    # Delete the associated shift if this is the last shift entry referencing it
    return unless shift.present? && shift.shift_entries.count == 1

    shift.destroy
  end
end
