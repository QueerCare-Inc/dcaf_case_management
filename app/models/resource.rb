class Resource < ApplicationRecord
  include PhoneCleanable

  before_save :clean_resource_phone_number 
  # Relations
  has_many :regions

  # Validations
  validates :website_link,
            :phone_number,
            :email,
            :contact_person,
            :services_provided,
            presence: true
  validates :phone_number, presence: true, phone: { possible: true, allow_blank: true }

  # Validations
  validate :regions_length
  validates :regions, presence: true

  # Methods
  def has_regions
    region.map { |region| region.present? }.any?
  end

  private

  def regions_length
    errors.add(:regions, 'is invalid') unless regions.length <= 10

    regions.each do |value|
      errors.add(:regions, 'is invalid') if value && value.length > 50
    end
  end

  def clean_resource_phone_number
    self.phone_number = clean_phone_number(phone_number)
  end
end
