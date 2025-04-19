# Object representing core personal information and demographic data.
class Person < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  include Callable
  include Notetakeable
  include AttributeDisplayable
  include EventLoggable
  # include UserTypeable

  # Callbacks
  before_validation :clean_fields
  before_save :save_identifier
  after_destroy :destroy_associated

  # Relationships
  belongs_to :region
  belongs_to :user
  # belongs_to :user_typeable
  has_many :notes, as: :can_note
  # belongs_to :last_edited_by, class_name: 'User', inverse_of: nil, optional: true
  has_one :patient, required: false
  has_one :volunteer, required: false
  has_one :care_coordinator, required: false

  # Validations
  # Worry about uniqueness to tenant after porting region info.
  # validates_uniqueness_to_tenant :primary_phone
  # validates :region, presence: true
  validates :emergency_contact_phone, format: /\A\d{10}\z/,
                                      length: { is: 10 },
                                      allow_blank: true
  validates :age,
            numericality: { only_integer: true, allow_nil: true, greater_than_or_equal_to: 0 }
  validates :household_size_adults, :household_size_children,
            numericality: { only_integer: true, allow_nil: true, greater_than_or_equal_to: -1 }
  validates :emergency_contact, :emergency_contact_phone, :emergency_contact_relationship,
            :language, :city, :state, :zipcode, :race_ethnicity, :employment_status,
            :income, length: { maximum: 150 }

  # validation for standard US zipcodes
  # allow ZIP (NNNNN) or ZIP+4 (NNNNN-NNNN)
  validates :zipcode, format: /\A\d{5}(-\d{4})?\z/,
                      length: { minimum: 5, maximum: 10 },
                      allow_blank: true

  validate :special_circumstances_length

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
    # CallListEntry.where(person_id: id).destroy_all
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

  def notes_count
    notes.size
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
      primary_phone_display: primary_phone_display,
      email_display: email_display
    )
  end

  def create_new_patient
    return unless user.role == 'cr'

    Patient.create(
      user_id: user_id,
      region_id: user.region_id,
      # region: user.region,
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
      # region: user.region,
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
end
