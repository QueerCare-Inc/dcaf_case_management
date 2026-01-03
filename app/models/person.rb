# Object representing core personal information and demographic data.
class Person < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  include CareRequestListable
  include Notetakeable
  # include AttributeDisplayable
  include EventLoggable
  include PersonSearchable
  include PhoneCleanable

  encrypts :emergency_contact_phone
  encrypts :emergency_contact

  # Callbacks
  before_validation :clean_fields
  before_save :save_identifier
  after_destroy :destroy_associated
  # before_save :clean_primary_phone_number
  before_save :clean_emergency_contact_phone_number

  # Relationships
  belongs_to :region
  belongs_to :user
  has_many :notes, as: :can_note, dependent: :destroy
  has_one :patient, required: false, dependent: :destroy
  has_one :volunteer, required: false, dependent: :destroy
  has_one :care_coordinator, required: false, dependent: :destroy

  # Validations
  # Worry about uniqueness to tenant after porting region info.
  # validates :primary_phone, presence: true, phone: { possible: true, allow_blank: false }
  validates :emergency_contact_phone, phone: { possible: true, allow_blank: true }
  validates :age,
            numericality: { only_integer: true, allow_nil: true, greater_than_or_equal_to: 0 }
  validates :household_size_adults, :household_size_children,
            numericality: { only_integer: true, allow_nil: true, greater_than_or_equal_to: -1 }
  validates :emergency_contact, :emergency_contact_phone, :emergency_contact_relationship,
            :language, :city, :state, :zipcode, :race_ethnicity, :employment_status,
            :income, length: { maximum: 150 }
  validate :emergency_contact_options_length

  # validation for standard US zipcodes
  # allow ZIP (NNNNN) or ZIP+4 (NNNNN-NNNN)
  validates :zipcode, format: /\A\d{5}(-\d{4})?\z/,
                      length: { minimum: 5, maximum: 10 },
                      allow_blank: true
  validate :must_have_user

  # Methods
  def save_identifier
    # [Region first initial][Phone 6th digit]-[Phone last four]
    region_now = Region.find(region_id)
    self.identifier = "#{region_now.name[0].upcase}#{user.primary_phone[-5]}-#{user.primary_phone[-4..-1]}"
  end

  def initials
    user.name.split(' ').map { |part| part[0] }.join('')
  end

  def okay_to_destroy?
    false
  end

  def destroy_associated
    # Event.where(person_id: id).destroy_all
    CareCoordinator.where(person_id: id).destroy_all
    Volunteer.where(person_id: id).destroy_all
    Patient.where(person_id: id).destroy_all
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

  def emergency_contact_phone_display
    return nil unless emergency_contact_phone.present?

    "#{emergency_contact_phone[0..2]}-#{emergency_contact_phone[3..5]}-#{emergency_contact_phone[6..9]}"
  end

  def notes_count
    notes.size
  end

  def has_emergency_contact_options
    emergency_contact_options.map { |option| option.present? }.any?
  end

  def has_special_circumstances
    special_circumstances.map { |circumstance| circumstance.present? }.any?
  end

  def recent_history_tracks
    versions.where(updated_at: 6.days.ago..)
  end

  # when we update the patient async (via React), we return the updated patient as json
  # as_json will return the AR attributes stored in the db by default
  # we extend it here to also include some of the additional custom getters we've written
  # (that aren't stored in the db but are derived from db values)
  def as_json
    super.merge(
      status: status,
      emergency_contact_phone_display: emergency_contact_phone_display
    )
  end

  def get_user_information
    user = User.find(user_id).first
    return nil unless user

    # Return a hash with user information
    {
      id: user.id,
      name: user.name,
      primary_phone: user.primary_phone,
      pronouns: user.pronouns,
      email: user.email,
      role: user.role,
      region_id: user.region_id,
      org_id: user.org_id
    }
  end

  def create_new_patient
    return unless user.role == 'cr'

    Patient.create(
      user_id: user_id,
      region_id: user.region_id,
      person_id: id,
      org_id: user.org_id
    )
  end

  def create_new_volunteer
    return unless user.role == 'volunteer'

    Volunteer.create(
      user_id: user_id,
      region_id: user.region_id,
      person_id: id,
      org_id: user.org_id
    )
  end

  def create_new_care_coordinator
    return unless user.role == 'care_coordinator'

    CareCoordinator.create(
      user_id: user_id,
      region_id: user.region_id,
      person_id: id,
      org_id: user.org_id
    )
  end

  private

  def clean_fields
    emergency_contact_phone.gsub!(/\D/, '') if emergency_contact_phone
    emergency_contact.strip! if emergency_contact
    emergency_contact_relationship.strip! if emergency_contact_relationship

    # add dash if needed
    zipcode.gsub!(/(\d{5})(\d{4})/, '\1-\2') if zipcode
  end

  # def clean_primary_phone_number
  #   self.primary_phone = clean_phone_number(primary_phone)
  #   confirm_unique_phone_number(primary_phone)
  #   return if errors[:this_phone_number_is_already_taken].blank?

  #   errors.add(:primary_phone, 'is already taken in this region.')
  # end

  def clean_emergency_contact_phone_number
    self.emergency_contact_phone = clean_phone_number(emergency_contact_phone)
  end

  def emergency_contact_options_length
    errors.add(:emergency_contact_options, 'is invalid') unless emergency_contact_options.length <= 7

    emergency_contact_options.each do |value|
      errors.add(:emergency_contact_options, 'is invalid') if value && value.length > 120
    end
  end

  def must_have_user
    errors.add(:user, I18n.t('errors.person.must_have_user')) unless user.present?
  end
end
