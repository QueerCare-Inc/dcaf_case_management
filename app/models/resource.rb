class Resource < ApplicationRecord
  # Relations
  has_many :regions

  # Validations
  validates :website_link,
            :phone,
            :email,
            :contact_person,
            :services_provided,
            presence: true

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
end
