class NewShiftForm
  include ActiveModel::Model

  attr_accessor :region_id, :org_id, :patient_id, :procedure_id, :care_address_id,
                :shift_type, :services, :start_time, :end_time

  validates :procedure_id, :care_address_id, :shift_type, :start_time, :end_time, presence: true

  def self.new_form_from_procedure(procedure)
    @care_address = CareAddress.new(
      region_id: procedure.region_id,
      org_id: procedure.org_id,
      patient_id: procedure.patient_id,
      procedure_id: procedure.id,
      start_date: Date.parse(procedure.procedure_date) + 1.day,
      end_date: Date.parse(procedure.procedure_date) + 1.week,

      street_address: '1 1st St',
      city: 'Washington',
      state: 'AL',
      zip: '00000',
      phone_number: '5555555555'
    )
  end

  def clean_new_care_address_phone_number
    self.phone_number = clean_phone_number(@phone_number)
  end

  def save
    clean_new_care_address_phone_number
    if valid?
      normalized_phone = Phonelib.parse(@phone_number).e164
      @region = Region.where(id: @region_id).first

      @care_address = CareAddress.create!(
        region_id: @region_id,
        org_id: @org_id,
        patient_id: @patient_id,
        procedure_id: @procedure_id,
        street_address: @street_address,
        city: @city,
        state: @state,
        zip: @zip,
        closest_cross_street: @closest_cross_street,
        phone_number: normalized_phone,
        start_date: @start_date,
        end_date: @end_date,
        confirmed: @confirmed,
        coordinates: @coordinates,
        qc_house: @qc_house,
        accessibility_options: @accessibility_options
      )
      true
    else
      false
    end
  end
end
