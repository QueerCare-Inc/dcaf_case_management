# Object representing core patient information and demographic data.
# TODO: fix create so that a Person object is also made
class Patient < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  include Shareable
  include CareRequestListable
  include Notetakeable
  include PersonSearchable
  include EventLoggable

  # Callbacks
  after_create :initialize_fulfillment
  after_update :confirm_still_shared, if: :shared_flag?
  after_update :update_care_coordinate_regions, if: :saved_change_to_region_id?
  after_update :update_current_procedure_id, if: :care_request_list_populated?
  after_destroy :destroy_associated

  # Relationships
  belongs_to :person
  belongs_to :region, optional: true
  belongs_to :user, optional: true
  has_many :notes, as: :can_note
  has_many :care_coordinate_entries, dependent: :destroy
  has_one :fulfillment, as: :can_fulfill
  has_many :procedures
  accepts_nested_attributes_for :procedures

  # Enable mass posting in forms
  accepts_nested_attributes_for :fulfillment

  # Validations
  # Worry about uniqueness to tenant after porting region info.
  # validates_uniqueness_to_tenant :primary_phone
  # validates :intake_date, presence: true

  validates :insurance, :referred_by, length: { maximum: 150 }
  validates :voicemail_preference, :care_coordinator, length: { maximum: 150 }
  validates_associated :fulfillment

  validate :in_case_of_emergency_length
  validate :emergency_contact_options_length

  # Methods
  def event_params
    {
      # care_coordinator_name: updated_by&.name || 'System',
      patient_name: user.name,
      patient_id: id,
      region_id: region_id
      # region: region
    }
  end

  def notes_count
    notes.size
  end

  def okay_to_destroy?
    false
  end

  # def destroy_associated
  #   Event.where(patient_id: id).destroy_all
  #   CareCoordinateEntry.where(patient_id: id).destroy_all
  #   Procedure.where(patient_id: id).destroy_all # NOTE: these should be archived before they can be deleted here
  #   Reimbursement.where(patient_id: id).destroy_all # NOTE: these should be archived before they can be deleted here
  # end

  def update_care_request_list_regions
    CareRequestListEntry.where(patient: self, procedure_id: self.current_procedure_id)
                 .update(region_id: region_id, order_key: 999)
  end

  def has_in_case_of_emergency
    in_case_of_emergency.map { |emergency| emergency.present? }.any?
  end

  def has_emergency_contact_options
    emergency_contact_options.map { |option| option.present? }.any?
  end

  def archive_date
    if fulfillment.audited?
      # If a patient fulfillment is ticked off as audited, archive 3 months
      # after initial call date. If we're already past 3 months later when
      # the audit happens, it will archive that night
      intake_date + Config.archive_fulfilled_patients.days
    else
      # If a patient is waiting for audit they archive a year after their
      # initial call date
      intake_date + Config.archive_all_patients.days
    end
  end

  def all_versions(include_fulfillment)
    all_versions = versions || []
    if include_fulfillment
      all_versions += fulfillment.versions.includes(fulfillment.versions.count > 1 ? [:item, :user] : []) || []
    end
    all_versions.sort_by(&:created_at).reverse
  end


  def get_person
    base_person = Person
    base_person.where(id: person_id)
  end

  def create_new_procedure
    Procedure.create(
      org_id: org_id,
      region_id: region_id,
      person_id: person_id,
      patient_id: id,
      procedure_date: Date.today,
      procedure_type: :other,
      care_status: :new_care_request
    )
  end

  def procedure_search(search_limit: 5)
      
    base_procedure = Procedure
    procedure_matches = base_procedure.where(patient_id: id)
    
    procedure_matches.limit(search_limit) if search_limit.present?
  end

  def care_request_list_populated?
    procedure_search.length > 0
  end

  def update_current_procedure_id
    base_procedure = procedure_search
    future_procedures = base_procedure.where('procedure_date > ?', DateTime.now)
    # ToDo: add a way to remove procedures that were an error
    current_procedure = future_procedures.first
    if current_procedure != nil
      self.current_procedure_id = current_procedure.id
    end
  end

  def get_current_procedure_id
    update_current_procedure_id
    return current_procedure_id
  end

  def intake_date_display
    return nil unless intake_date.present?
    # "#{intake_date.display_date}"
    intake_date.display_date
  end

  private

  def initialize_fulfillment
    build_fulfillment.save
  end

  def self.fulfilled_on_or_before(datetime)
    Patient.where('fulfillment.fulfilled' => true,
                  updated_at: { '$lte' => datetime })
  end

  def in_case_of_emergency_length
    errors.add(:in_case_of_emergency, 'is invalid') unless in_case_of_emergency.length <= 7

    in_case_of_emergency.each do |value|
      errors.add(:in_case_of_emergency, 'is invalid') if value && value.length > 120
    end
  end

  def emergency_contact_options_length
    errors.add(:emergency_contact_options, 'is invalid') unless emergency_contact_options.length <= 7

    emergency_contact_options.each do |value|
      errors.add(:emergency_contact_options, 'is invalid') if value && value.length > 120
    end
  end
end
