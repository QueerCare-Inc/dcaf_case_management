# Object representing core patient information and demographic data.
class Patient < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  include Shareable
  include Callable
  include Notetakeable
  include PatientSearchable
  include Statusable
  include Exportable
  include EventLoggable

  # Callbacks
  after_create :initialize_fulfillment
  after_update :confirm_still_shared, if: :shared_flag?
  after_update :update_call_list_regions, if: :saved_change_to_region_id?
  after_destroy :destroy_associated

  # Relationships
  belongs_to :person
  belongs_to :region, optional: true
  belongs_to :user, optional: true
  has_many :notes, as: :can_note
  has_many :call_list_entries, dependent: :destroy
  # has_many :users, through: :call_list_entries
  # belongs_to :clinic, optional: true
  has_one :fulfillment, as: :can_fulfill
  has_many :calls, as: :can_call
  # has_many :practical_supports, as: :can_support
  has_many :procedures

  # Enable mass posting in forms
  accepts_nested_attributes_for :fulfillment

  # Validations
  # Worry about uniqueness to tenant after porting region info.
  # validates_uniqueness_to_tenant :primary_phone
  # validates :intake_date, presence: true

  # validates :procedure_date, format: /\A\d{4}-\d{1,2}-\d{1,2}\z/,
  #                            allow_blank: true
  validates :insurance, :referred_by, length: { maximum: 150 }
  # validate :confirm_appointment_after_initial_call
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

  def destroy_associated
    Event.where(patient_id: id).destroy_all
    CallListEntry.where(patient_id: id).destroy_all
    Procedure.where(patient_id: id).destroy_all # NOTE: these should be archived before they can be deleted here
    Reimbursement.where(patient_id: id).destroy_all # NOTE: these should be archived before they can be deleted here
  end

  def update_call_list_regions
    CallListEntry.where(patient: self)
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
    # all_versions += practical_supports.includes(versions: [:item, :user]).map(&:versions).reduce(&:+) || []
    if include_fulfillment
      all_versions += fulfillment.versions.includes(fulfillment.versions.count > 1 ? [:item, :user] : []) || []
    end
    all_versions.sort_by(&:created_at).reverse
  end

  private

  # def confirm_appointment_after_initial_call
  #   return unless procedure_date.present? && intake_date&.send(:>, procedure_date)

  #   errors.add(:procedure_date, 'must be after date of initial call')
  # end

  def initialize_fulfillment
    build_fulfillment.save
  end

  def self.fulfilled_on_or_before(datetime)
    Patient.where('fulfillment.fulfilled' => true,
                  updated_at: { '$lte' => datetime })
  end

  # def self.unconfirmed_practical_support(region)
  #   Patient.distinct
  #          .where(region: region)
  #          .joins(:practical_supports)
  #          .where({ practical_supports: { confirmed: false }, created_at: 3.months.ago.. })
  # end

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
