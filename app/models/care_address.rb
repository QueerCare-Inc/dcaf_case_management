# Object representing an address instance at and during which a patient is receiving care.
class CareAddress < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable

  encrypts :street_address
  encrypts :city
  encrypts :state
  encrypts :zip
  encrypts :phone
  encrypts :start_date
  encrypts :end_date

  # Callbacks
  before_save :update_coordinates, if: :address_changed?
  belongs_to :region
  belongs_to :procedure
  belongs_to :patient
  belongs_to :qc_housing
  has_many :shifts, as: :can_shift

  # Validations
  validates :street_address, :city, :state, :zip, :closest_cross_street, :start_date, :end_date, presence: true
  validates :street_address, :city, :state, :zip, :closest_cross_street, :phone, :start_date, :end_date,
            length: { maximum: 150 }

  validate :confirm_care_after_procedure
  validate :confirm_end_date_after_start_date

  # Methodsconfirm_end_date_after_start_date
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

    all.each { |care_address| care_address.update_coordinates && care_address.save }
  end

  private

  def confirm_care_after_procedure
    return unless start_date.present? && procedure.procedure_date&.send(:>, start_date)
    return unless end_date.present? && procedure.procedure_date&.send(:>, end_date)

    errors.add(:start_date, 'and', :end_date, 'must be after date of procedure')
  end

  def confirm_end_date_after_start_date
    return unless start_date.present? && end_date.present? && start_date&.send(:>, end_date)

    errors.add(:start_date, 'must be before', :end_date)
  end
end
