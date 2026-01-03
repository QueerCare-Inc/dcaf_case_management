# Representation of non-monetary assistance coordinated for a patient.
class Shift < ApplicationRecord
  acts_as_tenant :org

  encrypts :attachment_url
  encrypts :start_time
  encrypts :end_time

  # Concerns
  include PaperTrailable
  include Notetakeable
  include ServiceTypeable
  include ShiftTypeable
  include DateDisplayable

  # Relationships
  belongs_to :region
  belongs_to :patient
  belongs_to :procedure
  belongs_to :care_address
  has_many :shift_entries, dependent: :destroy
  has_many :volunteers, through: :shift_entries

  # Validations
  validates :shift_type, :start_time, :end_time, presence: true, length: { maximum: 150 }

  validate :confirm_end_time_after_start_time
  # validate :must_have_shift_entry
  # validate :must_have_care_address

  validate :services_length
  # validate :volunteers_length

  # enum :service_type, {
  #   personal_care: 0,
  #   meals: 1,
  #   chores: 2,
  #   grocery_shopping: 3,
  #   prescriptions: 4,
  #   transportation: 5,
  #   companionship: 6,
  #   other_service: 7
  # }
  enum :shift_type, {
    in_home: 0,
    errands: 1,
    transport: 2,
    virtual: 3,
    other_shift: 4,
    overnight: 5
  }

  def has_services
    services.map { |service| service.present? }.any?
  end

  def has_volunteers
    volunteers.map { |volunteer| volunteer.present? }.any?
  end

  def services_length
    # The max length is (2 x n) where n is the number of services checkboxes. With no
    # boxes checked, there are n elements (all blank), and there is an additional element present
    # for every checked box.
    errors.add(:services, 'is invalid') unless services.length <= 14

    services.each do |value|
      errors.add(:services, 'is invalid') if value && value.length > 50
    end
  end

  def volunteers_length
    errors.add(:volunteers, 'is invalid') unless volunteers.length <= 10

    volunteers.each do |value|
      errors.add(:volunteers, 'is invalid') if value && value.length > 50
    end
  end

  def confirm_end_time_after_start_time
    unless start_time.present? && end_time.present? && DateTime.parse(start_time).after?(DateTime.parse(end_time))
      return
    end

    errors.add(:start_time, 'must be before', :end_time)
  end

  def must_have_shift_entry
    return if shift_entries.present? && shift_entries.any?

    errors.add(:shift_entries,
               I18n.t('errors.shift.must_have_shift_entry'))
  end

  # def must_have_care_address
  #   errors.add(:care_address, I18n.t('errors.shift.must_have_care_address')) unless care_address.present?
  # end
end
