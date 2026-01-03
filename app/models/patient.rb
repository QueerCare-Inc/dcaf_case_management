# Object representing core patient information and demographic data.
# TODO: fix create so that a Person object is also made
class Patient < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  include Shareable
  # include CareRequestListable
  include Notetakeable
  include PersonSearchable
  include EventLoggable
  include DateDisplayable

  encrypts :legal_name
  encrypts :intake_date

  # Callbacks
  after_create :initialize_fulfillment
  after_create :create_care_request_entry
  after_update :confirm_still_shared, if: :shared_flag?
  after_update :update_care_coordinate_regions, if: :saved_change_to_region_id?
  after_update :update_current_procedure_id, if: :care_request_list_populated?
  after_destroy :destroy_associated

  # Relationships
  belongs_to :person
  belongs_to :region, optional: true
  belongs_to :user, optional: true
  # belongs_to :care_coordinator, optional: true
  has_many :notes, as: :can_note, dependent: :destroy
  # has_many :care_coordinate_entries, dependent: :destroy
  has_one :fulfillment, as: :can_fulfill
  has_many :shift_entries, dependent: :destroy
  has_many :shifts, through: :shift_entries, dependent: :destroy
  has_many :care_addresses, through: :shift_entries, dependent: :destroy
  has_many :procedures, through: :shift_entries, dependent: :destroy
  has_many :care_request_entries, dependent: :destroy
  accepts_nested_attributes_for :care_request_entries, allow_destroy: true

  # has_many :care_request_list_entries, dependent: :destroy
  accepts_nested_attributes_for :procedures
  belongs_to :last_edited_by, class_name: 'User', inverse_of: nil, optional: true

  # Enable mass posting in forms
  accepts_nested_attributes_for :fulfillment

  # Validations
  # Worry about uniqueness to tenant after porting region info.
  # validates_uniqueness_to_tenant :primary_phone
  # validates :intake_date, presence: true

  validates :insurance, :referred_by, length: { maximum: 150 }
  validates :voicemail_preference, length: { maximum: 150 } # :care_coordinator,
  validates_associated :fulfillment

  validate :in_case_of_emergency_length
  validate :special_circumstances_length
  validate :must_have_person

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
    CareRequestListEntry.where(patient: self, procedure_id: current_procedure_id)
                        .update(region_id: region_id, order_key: 999)
  end

  def has_in_case_of_emergency
    in_case_of_emergency.map { |emergency| emergency.present? }.any?
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
    Procedure.transaction do
      # Create the Procedure without validation
      procedure = Procedure.new(
        org_id: org_id,
        region_id: region_id,
        person_id: person_id,
        patient_id: id,
        procedure_date: Date.today + 1.month,
        procedure_type: Procedure.procedure_types[:other],
        care_status: Procedure.care_statuses[:new_care_request]
      )
      procedure.save!(validate: false)

      # Create the CareRequestEntry and associate it with the Procedure
      care_request_entry = CareRequestEntry.create!(
        patient: self,
        procedure: procedure,
        region: region,
        care_coordinator: nil # Set this if applicable
      )
      # Update the Procedure with the CareRequestEntry
      procedure.update!(care_request_entry: care_request_entry)

      procedure
    end
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

    future_procedures = base_procedure.where('procedure_date >= ?', DateTime.now)
    # TODO: add a way to remove procedures that were an error
    current_procedure = future_procedures.first
    return if current_procedure.nil?

    self.current_procedure_id = current_procedure.id
  end

  def get_current_procedure_id
    update_current_procedure_id
    current_procedure_id
  end

  def get_current_procedure
    update_current_procedure_id
    return Procedure.find_by(id: current_procedure_id) if current_procedure_id.present?

    nil
  end

  def get_all_procedures
    base_procedure = Procedure
    base_procedure.where(patient_id: id).order(procedure_date: :asc)
  end

  def intake_date_display
    return nil unless intake_date.present?

    # "#{intake_date.display_date}"
    intake_date.display_date
  end

  def get_all_shifts
    Shift.where(patient_id: id).sort_by(&:start_time)
  end

  def create_care_request_entry
    procedure = get_current_procedure
    CareRequestEntry.create_care_request_entry(
      patient: self,
      procedure: procedure,
      region: region
    )
  end

  private

  def initialize_fulfillment
    build_fulfillment.save
  end

  def self.fulfilled_on_or_before(datetime)
    Patient.where('fulfillment.fulfilled' => true,
                  updated_at: { '$lte' => datetime })
  end

  # This is intended to protect against saving maliscious data sent via an edited request. It should
  # not be possible to trigger errors here via the UI.
  def special_circumstances_length
    # The max length is (2 x n) where n is the number of special circumstances checkboxes. With no
    # boxes checked, there are n elements (all blank), and there is an additional element present
    # for every checked box.
    errors.add(:special_circumstances, 'is invalid') unless special_circumstances.length <= 14

    special_circumstances.each do |value|
      errors.add(:special_circumstances, 'is invalid') if value && value.length > 50
    end
  end

  def in_case_of_emergency_length
    errors.add(:in_case_of_emergency, 'is invalid') unless in_case_of_emergency.length <= 7

    in_case_of_emergency.each do |value|
      errors.add(:in_case_of_emergency, 'is invalid') if value && value.length > 120
    end
  end

  def must_have_person
    errors.add(:person, I18n.t('errors.patient.must_have_person')) unless person.present?
  end
end
