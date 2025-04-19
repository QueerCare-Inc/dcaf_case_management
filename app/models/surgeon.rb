# Object representing a surgeon that a patient is going to.
class Surgeon < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable

  encrypts :name, deterministic: true
  encrypts :phone

  belongs_to :region
  # has_many :surgeons_clinics
  has_many :clinics, through: :surgeons_clinics
  has_many :procedures, as: :can_procedure

  # Validations
  validates :name, :phone, presence: true
  validates :name, :phone, :email,
            length: { maximum: 150 }
  validates_uniqueness_to_tenant :name

  validate :procedures_length
  validate :insurances_length

  # Methods
  def has_procedures
    procedures.map { |procedure| procedure.present? }.any?
  end

  def has_insurances
    insurances.map { |insurance| insurance.present? }.any?
  end

  def procedures_length
    errors.add(:procedures, 'is invalid') unless procedures.length <= 10

    procedures.each do |value|
      errors.add(:procedures, 'is invalid') if value && value.length > 50
    end
  end

  def insurances_length
    errors.add(:insurances, 'is invalid') unless insurances.length <= 100

    insurances.each do |value|
      errors.add(:insurances, 'is invalid') if value && value.length > 50
    end
  end
end
