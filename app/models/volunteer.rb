# Object representing core volunteer information and demographic data.
class Volunteer < ApplicationRecord
  acts_as_tenant :org
  
  # Concerns
  include PaperTrailable
  include PersonSearchable

  # Callbacks
  after_destroy :destroy_associated

  # Relationships
  belongs_to :qc_housing
  belongs_to :person
  belongs_to :region, optional: true
  belongs_to :user, optional: true
  # has_many :notes, as: :can_note #TODO: update the structure of notes or add new note type
  # has_many :call_list_entries, dependent: :destroy #TODO: update the structure of calls and events or create new types

  # has_many :shifts_volunteers
  has_many :shifts, through: :shifts_volunteers

  # Validations
  # Worry about uniqueness to tenant after porting region info.
  # validates_uniqueness_to_tenant :primary_phone
  # validate :shifts_length
  validate :volunteer_types_length
  
  # Methods
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
    Shift.where(volunteer_id: id).destroy_all # NOTE: this should be archived
    QcHousing.where(volunteer_id: id).destroy_all
  end

  def search_volunteers(name_or_phone_str, regions: nil, search_limit: DEFAULT_SEARCH_LIMIT)
    people = search(name_or_phone_str, regions, search_limit)
    base = Volunteer
    matches = base.where(person_id: people.id)
    matches.order(updated_at: :desc)
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
end
