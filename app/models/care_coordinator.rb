# Object representing core patient information and demographic data.
class CareCoordinator < ApplicationRecord
  acts_as_tenant :org
  has_many :patients, as: :can_patient

  # Concerns
  include PaperTrailable
  # include Notetakeable
  include PersonSearchable

  # Callbacks
  after_destroy :destroy_associated

  # Relationships
  # belongs_to :qc_housing #TODO: revisit this relationship
  belongs_to :person
  belongs_to :region, optional: true
  belongs_to :user, optional: true
  # has_many :notes, as: :can_note #TODO: update the structure of notes or add new note type
  has_many :shift_entries, dependent: :nullify
  has_many :shifts, through: :shift_entries, dependent: :nullify
  has_many :procedures, through: :shift_entries, dependent: :nullify
  has_many :patients, through: :shift_entries, dependent: :nullify
  # accepts_nested_attributes_for :shifts

  # Validations
  # Worry about uniqueness to tenant after porting region info.
  # validates_uniqueness_to_tenant :primary_phone
  # validate :shifts_length
  validate :volunteer_types_length
  validate :must_have_person

  # Methods
  # def has_patients
  #   patients.map { |patient| patient.present? }.any?
  # end

  # def has_shifts
  #   shifts.map { |shift| shift.present? }.any?
  # end
  # def notes_count
  #   notes.size
  # end

  def has_volunteer_types
    volunteer_types.map { |volunteer_type| volunteer_type.present? }.any?
  end

  def okay_to_destroy?
    false
  end

  def destroy_associated
    # NOTE: these relationships need to be defined first
    # Shift.where(care_coordinator_id: id).destroy_all # NOTE: this should be archived
    # QcHousing.where(care_coordinator_id: id).destroy_all
  end

  def search_care_coordinator(name_or_phone_str, regions: nil, search_limit: DEFAULT_SEARCH_LIMIT)
    people = search(name_or_phone_str, regions, search_limit)
    base = CareCoordinator
    matches = base.where(person_id: people.id)
    matches.order(updated_at: :desc)
  end

  def get_patients_list
    base_patient = Patient
    base_patient.where(care_coordinator_id: id)
  end

  private

  # def shifts_length
  #   errors.add(:shifts, 'is invalid') unless shifts.length <= 100

  #   shifts.each do |value|
  #     errors.add(:shifts, 'is invalid') if value && value.length > 50
  #   end
  # end

  def volunteer_types_length
    errors.add(:volunteer_types, 'is invalid') unless volunteer_types.length <= 10

    volunteer_types.each do |value|
      errors.add(:volunteer_types, 'is invalid') if value && value.length > 50
    end
  end

  # def patients_length
  #   errors.add(:patients, 'is invalid') unless patients.length <= 100

  #   patients.each do |value|
  #     errors.add(:patients, 'is invalid') if value && value.length > 50
  #   end
  # end

  def must_have_person
    errors.add(:person, I18n.t('errors.care_coordinator.must_have_person')) unless person.present?
  end
end
