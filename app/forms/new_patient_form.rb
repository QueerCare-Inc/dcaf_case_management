class NewPatientForm
  # acts_as_tenant :org

  include ActiveModel::Model

  include PhoneCleanable

  # before_save :clean_new_patient_phone_number, if: :primary_phone_changed?
  
  attr_accessor :region_id, :org_id, :primary_phone, :name, :email, :procedure_date, :procedure_type

  validates :primary_phone, presence: true, phone: { possible: true, allow_blank: false }
  # validates :region_id, :org_id, :primary_phone, :name, presence: true


  def save
    clean_new_patient_phone_number
    if valid?
      normalized_phone = Phonelib.parse(primary_phone).e164

      @region = Region.where(id: region_id).first
      @person = Person.create(
        region_id: region_id, 
        org_id: org_id,
        primary_phone: normalized_phone,
        name: name,
        email: email
        )
      @patient = Patient.create(
        person_id: @person.id, 
        region_id: region_id, 
        org_id: org_id
        )
      @procedure = Procedure.create(
        patient_id: @patient.id,
        person_id: @person.id, 
        region_id: region_id, 
        org_id: org_id,
        procedure_date: procedure_date,
        procedure_type: procedure_type,
        care_status: 'new_care_request'
      )
      true
    else
      false
    end
  end

  def clean_new_patient_phone_number
    self.primary_phone = clean_phone_number(primary_phone)
  end
end