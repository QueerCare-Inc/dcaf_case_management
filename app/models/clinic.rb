# Object representing a clinic that a patient is going to.
class Clinic < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable

  # Clinics intentionally excluded from ClinicFinder are assigned the zip 99999.
  # e.g. so a org can have an 'OTHER CLINIC' catchall.
  EXCLUDED_ZIP = '99999'

  encrypts :name, deterministic: true
  encrypts :street_address
  encrypts :city
  encrypts :state
  encrypts :zip
  encrypts :phone
  encrypts :fax

  # Callbacks
  before_save :update_coordinates, if: :address_changed?
  belongs_to :region
  # has_many :surgeons_clinics
  has_many :surgeons, through: :surgeons_clinics

  # Validations
  validates :name, :street_address, :city, :state, :zip, presence: true
  validates :name, :street_address, :city, :state, :zip, :phone, :fax,
            length: { maximum: 150 }
  validates_uniqueness_to_tenant :name

  # Methods
  def display_location
    return nil if city.blank? || state.blank?

    "#{city}, #{state}"
  end

  def display_coordinates
    coordinates.map(&:to_f)
  end

  def full_address
    return nil if display_location.blank? || street_address.blank? || zip.blank?

    "#{street_address}, #{display_location} #{zip}"
  end

  def update_coordinates
    geocoder = Geokit::Geocoders::GoogleGeocoder
    return unless geocoder.try :api_key

    location = geocoder.geocode full_address
    coordinates = [location.lat, location.lng]
    self.coordinates = coordinates
  end

  def address_changed?
    street_address_changed? || city_changed? || state_changed? || zip_changed?
  end

  def self.update_all_coordinates
    raise Exceptions::NoGoogleGeoApiKeyError.new unless Geokit::Geocoders::GoogleGeocoder.try(:api_key)

    all.each { |clinic| clinic.update_coordinates && clinic.save }
  end
end
