# Object representing core patient information and demographic data.
class Patient < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  include Shareable
  include Callable
  include Notetakeable
  include PatientSearchable
  include AttributeDisplayable
  include Statusable
  include Exportable
  include EventLoggable
  # include UserTypeable

  # Callbacks
  before_validation :clean_fields
  before_save :save_identifier
  after_create :initialize_fulfillment
  after_update :confirm_still_shared, if: :shared_flag?
  after_update :update_call_list_regions, if: :saved_change_to_region_id?
  after_destroy :destroy_associated_events

  # Relationships
  belongs_to :region
  # belongs_to :user_typeable
  has_many :call_list_entries, dependent: :destroy
  # has_many :users, through: :call_list_entries
  belongs_to :clinic, optional: true
  has_one :fulfillment, as: :can_fulfill
  has_many :calls, as: :can_call
  has_many :practical_supports, as: :can_support
  has_many :notes, as: :can_note
  belongs_to :last_edited_by, class_name: 'User', inverse_of: nil, optional: true

  # Enable mass posting in forms
  accepts_nested_attributes_for :fulfillment

  # Validations
  # Worry about uniqueness to tenant after porting region info.
  # validates_uniqueness_to_tenant :primary_phone
  validates :intake_date,
            :region,
            presence: true
  validates :emergency_contact_phone, format: /\A\d{10}\z/,
                                      length: { is: 10 },
                                      allow_blank: true
  validates :procedure_date, format: /\A\d{4}-\d{1,2}-\d{1,2}\z/,
                             allow_blank: true
  validate :confirm_appointment_after_initial_call
  validates :age,
            numericality: { only_integer: true, allow_nil: true, greater_than_or_equal_to: 0 }
  validates :household_size_adults, :household_size_children,
            numericality: { only_integer: true, allow_nil: true, greater_than_or_equal_to: -1 }
  validates :emergency_contact, :emergency_contact_phone, :emergency_contact_relationship,
            :voicemail_preference, :language, :city, :state, :county, :zipcode, :care_coordinator,
            :race_ethnicity, :employment_status, :insurance, :income, :referred_by, :procedure_type,
            length: { maximum: 150 }
  validates_associated :fulfillment

  # validation for standard US zipcodes
  # allow ZIP (NNNNN) or ZIP+4 (NNNNN-NNNN)
  validates :zipcode, format: /\A\d{5}(-\d{4})?\z/,
                      length: { minimum: 5, maximum: 10 },
                      allow_blank: true

  validate :special_circumstances_length
  validate :in_case_of_emergency_length

  # Methods
  def save_identifier
    # [Region first initial][Phone 6th digit]-[Phone last four]
    self.identifier = "#{region.name[0].upcase}#{user.primary_phone[-5]}-#{user.primary_phone[-4..-1]}"
  end

  def initials
    user.name.split(' ').map { |part| part[0] }.join('')
  end

  def event_params
    {
      care_coordinator_name: updated_by&.name || 'System',
      patient_name: user.name,
      patient_id: id,
      region: region
    }
  end

  def okay_to_destroy?
    false
  end

  def destroy_associated_events
    Event.where(patient_id: id).destroy_all
    CallListEntry.where(patient_id: id).destroy_all
  end

  def update_call_list_regions
    CallListEntry.where(patient: self)
                 .update(region: region, order_key: 999)
  end

  def has_alt_contact
    emergency_contact.present? || emergency_contact_phone.present? || emergency_contact_relationship.present?
  end

  def age_range
    case age
    when nil, ''
      :not_specified
    when 1..17
      :under_18
    when 18..24
      :age18_24
    when 25..34
      :age25_34
    when 35..44
      :age35_44
    when 45..54
      :age45_54
    when 55..100
      :age55plus
    else
      :bad_value
    end
  end

  def notes_count
    notes.size
  end

  def has_special_circumstances
    special_circumstances.map { |circumstance| circumstance.present? }.any?
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

  def recent_history_tracks
    versions.where(updated_at: 6.days.ago..)
  end

  def all_versions(include_fulfillment)
    all_versions = versions || []
    all_versions += practical_supports.includes(versions: [:item, :user]).map(&:versions).reduce(&:+) || []
    if include_fulfillment
      all_versions += fulfillment.versions.includes(fulfillment.versions.count > 1 ? [:item, :user] : []) || []
    end
    all_versions.sort_by(&:created_at).reverse
  end

  # when we update the patient async (via React), we return the updated patient as json
  # as_json will return the AR attributes stored in the db by default
  # we extend it here to also include some of the additional custom getters we've written
  # (that aren't stored in the db but are derived from db values)
  def as_json
    super.merge(
      status: status,
      primary_phone_display: primary_phone_display,
      email_display: email_display
    )
  end

  private

  def confirm_appointment_after_initial_call
    return unless procedure_date.present? && intake_date&.send(:>, procedure_date)

    errors.add(:procedure_date, 'must be after date of initial call')
  end

  def clean_fields
    emergency_contact_phone.gsub!(/\D/, '') if emergency_contact_phone
    emergency_contact.strip! if emergency_contact
    emergency_contact_relationship.strip! if emergency_contact_relationship

    # add dash if needed
    zipcode.gsub!(/(\d{5})(\d{4})/, '\1-\2') if zipcode
  end

  def initialize_fulfillment
    build_fulfillment.save
  end

  def self.fulfilled_on_or_before(datetime)
    Patient.where('fulfillment.fulfilled' => true,
                  updated_at: { '$lte' => datetime })
  end

  def self.unconfirmed_practical_support(region)
    Patient.distinct
           .where(region: region)
           .joins(:practical_supports)
           .where({ practical_supports: { confirmed: false }, created_at: 3.months.ago.. })
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
end
