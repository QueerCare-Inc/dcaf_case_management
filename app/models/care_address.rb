# Object representing an address instance at and during which a patient is receiving care.
class CareAddress < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable
  include PhoneCleanable
  include DateDisplayable

  encrypts :street_address
  encrypts :city
  encrypts :state
  encrypts :zip
  encrypts :phone_number
  encrypts :start_date
  encrypts :end_date

  # Callbacks
  before_save :update_coordinates, if: :address_changed?
  before_save :clean_care_address_phone_number
  # before_destroy :check_procedure_state
  before_destroy :handle_shifts

  belongs_to :region
  belongs_to :procedure
  belongs_to :patient
  # belongs_to :qc_housing
  has_many :shift_entries, dependent: :destroy
  has_many :shifts, through: :shift_entries
  has_many :volunteers, through: :shift_entries, dependent: :nullify
  # accepts_nested_attributes_for :shifts

  # Validations
  validates :street_address, :city, :state, :zip, :start_date, :end_date, presence: true # :closest_cross_street,
  validates :street_address, :city, :state, :zip, :closest_cross_street, :phone_number, :start_date, :end_date,
            length: { maximum: 150 }
  validates :phone_number, presence: true, phone: { possible: true, allow_blank: false }

  validate :confirm_care_after_procedure
  validate :confirm_end_date_after_start_date
  validate :must_have_procedure

  validate :accessibility_options_length, if: -> { accessibility_options.present? }

  validates :procedure_id,
            uniqueness: { scope: [:street_address, :city, :state, :zip, :start_date, :end_date],
                          message: 'This care address already exists for the procedure.' }

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

  def has_accessibility_options
    accessibility_options.map { |option| option.present? }.any?
  end

  def get_page_shifts(page, per_page = 10)
    # shifts = Shift.where(procedure_id: id)
    sorted_shifts = # Sort in Ruby
      shifts.sort_by do |shift|
        DateTime.parse(shift.start_time)
            rescue StandardError
              nil
      end
    Kaminari.paginate_array(sorted_shifts).page(page).per(per_page) # Paginate in memory
  end

  private

  def confirm_care_after_procedure
    if procedure.nil? & procedure_id.present?
      @procedure = Procedure.where(id: procedure_id).first
    elsif procedure.present?
      @procedure = procedure
    end
    if @procedure.present?
      return unless start_date.present? && Date.parse(start_date).before?(Date.parse(@procedure.procedure_date))
      return unless end_date.present? && Date.parse(end_date).before?(Date.parse(@procedure.procedure_date))

      errors.add(:start_date, 'and', :end_date, 'must be after date of procedure')
    end
    true
  end

  def confirm_end_date_after_start_date
    return unless start_date.present? && end_date.present? && Date.parse(start_date).after?(Date.parse(end_date))

    errors.add(:start_date, 'must be before', :end_date)
  end

  def clean_care_address_phone_number
    self.phone_number = clean_phone_number(phone_number)
  end

  def accessibility_options_length
    errors.add(:accessibility_options, 'is invalid') unless accessibility_options.length <= 7

    accessibility_options.each do |value|
      errors.add(:accessibility_options, 'is invalid') if value && value.length > 120
    end
  end

  # def check_procedure_state
  #   if procedure.care_addresses.count == 1
  #     # If this is the last CareAddress, you can either:
  #     # - Prevent the destruction
  #     # - Update the Procedure's state
  #     # - Notify the user/admin
  #     errors.add(:base, 'Cannot delete the last care address for a procedure')
  #     throw(:abort)
  #   end
  # end

  def must_have_procedure
    errors.add(:procedure, I18n.t('errors.care_address.must_have_procedure')) unless procedure.present?
  end

  def handle_shifts
    # Delete associated shift entries first
    shift_entries.destroy_all

    # Then delete or nullify shifts directly associated with this care address
    shifts.destroy_all
  end
end
