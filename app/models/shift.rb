# Representation of non-monetary assistance coordinated for a patient.
class Shift < ApplicationRecord
  acts_as_tenant :org

  encrypts :attachment_url
  encrypts :start_time
  encrypts :end_time

  # Concerns
  include PaperTrailable
  include Notetakeable

  # Relationships
  belongs_to :region
  belongs_to :procedure
  belongs_to :care_address
  belongs_to :patient
  # belongs_to :can_support, polymorphic: true
  # has_many :notes, as: :can_note
  # has_many :shifts_volunteers
  has_many :volunteers, through: :shifts_volunteers

  # Validations
  validates :type, :start_time, :end_time, presence: true, length: { maximum: 150 }

  validate :confirm_end_date_after_start_date

  validate :services_length
  validate :volunteers_length

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
    return unless start_time.present? && end_time.present? && start_time&.send(:>, end_time)

    errors.add(:start_time, 'must be before', :end_time)
  end
end
