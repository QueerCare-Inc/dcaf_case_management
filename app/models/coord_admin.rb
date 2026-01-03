# Object representing core patient information and demographic data.
class CoordAdmin < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  # include Notetakeable
  include PersonSearchable

  # Callbacks
  after_destroy :destroy_associated

  # Relationships
  belongs_to :person
  belongs_to :region, optional: true
  belongs_to :user, optional: true
  # has_many :notes, as: :can_note #TODO: update the structure of notes or add new note type

  # Validations
  # Worry about uniqueness to tenant after porting region info.
  # validates_uniqueness_to_tenant :primary_phone

  # def notes_count
  #   notes.size
  # end

  def okay_to_destroy?
    false
  end

  def destroy_associated
    # NOTE: these relationships need to be defined first
    # Shift.where(care_coordinator_id: id).destroy_all # NOTE: this should be archived
    # QcHousing.where(care_coordinator_id: id).destroy_all
  end

  def search_coord_admin(name_or_phone_str, regions: nil, search_limit: DEFAULT_SEARCH_LIMIT)
    people = search(name_or_phone_str, regions, search_limit)
    base = CoordAdmin
    matches = base.where(person_id: people.id)
    matches.order(updated_at: :desc)
  end

  def get_patients_list
    base_patient = Patient
    base_patient.where(org_id: org_id, region_id: region_id).order(updated_at: :desc)
  end

  private
end
