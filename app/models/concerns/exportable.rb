require 'csv'

# Methods pertaining to patient export
module Exportable
  extend ActiveSupport::Concern
  include ActionView::Helpers::NumberHelper

  CSV_EXPORT_FIELDS = {
    'BSON ID' => :id,
    # "Identifier" => :identifier,
    'Archived?' => :archived?,
    'Has Alt Contact?' => :has_alt_contact,
    'Voicemail Preference' => :voicemail_preference,
    'Region' => :get_region,
    'Language' => :preferred_language,
    'Age' => :age_range,
    'State' => :state,
    'County' => :county,
    'City' => :city,
    'Race or Ethnicity' => :race_ethnicity,
    'Employment Status' => :employment_status,
    'Minors in Household' => :get_household_size_children,
    'Adults in Household' => :get_household_size_adults,
    'Insurance' => :insurance,
    'Procedure Type' => :procedure_type,
    'Income' => :income,
    'Referred By' => :referred_by,
    'Referred to clinic by org' => :referred_to_clinic,
    'Procedure Date' => :procedure_date,
    'Intake Date' => :intake_date,
    'Shared?' => :shared_flag,
    'Has Special Circumstances' => :has_special_circumstances,
    'Clinic' => :export_clinic_name,
    'Multi-day appointment' => :multiday_appointment,
    'Practical Support Waiver' => :practical_support_waiver,

    # Call related
    'Timestamp of first call' => :first_call_timestamp,
    'Timestamp of last call' => :last_call_timestamp,
    'Call count' => :call_count,
    'Reached Patient call count' => :reached_patient_call_count,

    # Fulfillment related
    'Fulfilled' => :fulfilled,
    'Procedure date' => :procedure_date,

    # Notes
    'Notes Count' => :notes_count,

    # TODO: clinic stuff

    'Practical Supports' => :all_practical_supports

    # TODO: test to confirm that specific blacklisted fields aren't being exported
  }.freeze

  def get_region
    region.try :name
  end

  def fulfilled
    fulfillment.try :fulfilled
  end

  def archived?
    if is_a?(Patient)
      false
    else
      true
    end
  end

  def get_household_size_children
    if is_a?(Patient)
      household_size_children == -1 ? 'Prefer not to answer' : household_size_children
    else
      nil
    end
  end

  def get_household_size_adults
    if is_a?(Patient)
      household_size_adults == -1 ? 'Prefer not to answer' : household_size_adults
    else
      nil
    end
  end

  def procedure_date
    fulfillment.try :procedure_date
  end

  def first_call_timestamp
    calls.first.try :created_at
  end

  def last_call_timestamp
    calls.last.try :created_at
  end

  def call_count
    calls.size
  end

  def reached_patient_call_count
    calls.select { |call| call.reached_patient? }.size
  end

  def export_clinic_name
    clinic.try :name
  end

  def preferred_language
    case language
    when nil, ''
      'English'
    else
      language
    end
  end

  def get_field_value_for_serialization(field)
    value = public_send(field)
    if value.is_a?(Array)
      # Use simpler serialization for Array values than the default (`to_s`)
      sanitize(value.reject(&:blank?).join(', '))
    else
      sanitize(value)
    end
  end

  def sanitize(value)
    if value.is_a?(String) && value.start_with?(/\s*[=@+\-\t\r]/)
      # Escape certain special characters to prevent formula injection.
      "'#{value}"
    else
      value
    end
  end

  def all_practical_supports
    shaped_supports = practical_supports.map do |ps|
      src = ps.source
      typ = ps.support_type
      confirmed = ps.confirmed? ? 'Confirmed' : 'Unconfirmed'
      amt = ps.amount.present? ? number_to_currency(ps.amount) : '$0'
      url = ps.attachment_url.presence || 'No attachment'
      fulfilled = ps.fulfilled? ? 'Fulfilled' : 'Not fulfilled'
      purchased_on = ps.purchase_date ? "Purchased on #{ps.purchase_date.display_date}" : 'No purchase date'
      "#{src} - #{typ} - #{confirmed} - #{amt} - #{url} - #{fulfilled} - #{purchased_on}"
    end
    shaped_supports.join('; ')
  end

  PATIENT_RELATIONS = [:region, :clinic, :fulfillment, :calls, :practical_supports]
  ARCHIVED_PATIENT_RELATIONS = [:region, :clinic, :fulfillment, :calls, :practical_supports]

  class_methods do
    def csv_header
      Enumerator.new do |y|
        y << CSV.generate_region(CSV_EXPORT_FIELDS.keys, encoding: 'utf-8')
      end
    end

    def to_csv
      relations = if name == 'Patient'
                    PATIENT_RELATIONS
                  elsif name == 'ArchivedPatient'
                    ARCHIVED_PATIENT_RELATIONS
                  else
                    raise 'Trying to export something other than a Patient or ArchivedPatient'
                  end

      Enumerator.new do |y|
        includes(relations).each do |export|
          row = CSV_EXPORT_FIELDS.values.map { |field| export.get_field_value_for_serialization(field) }
          y << CSV.generate_region(row, encoding: 'utf-8')
        end
      end
    end
  end
end
