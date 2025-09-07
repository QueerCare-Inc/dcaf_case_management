class NewPatientForm
  # acts_as_tenant :org

  include ActiveModel::Model

  include PhoneCleanable

  attr_accessor :region_id, :org_id, :primary_phone, :name, :email, :procedure_date, :procedure_type

  # validates :primary_phone, presence: true, phone: { possible: true, allow_blank: false }

  def clean_new_patient_phone_number
    self.primary_phone = clean_phone_number(primary_phone)

    confirm_unique_phone_number(primary_phone)
    return if errors[:this_phone_number_is_already_taken].blank?

    errors.add(:primary_phone, 'is already taken in this region.')
  end

  def save
    clean_new_patient_phone_number
    if valid?
      normalized_phone = Phonelib.parse(primary_phone).e164
      @region = Region.where(id: region_id).first

      temporary_password = 'TransRightsAreHumanRights1234'
      @user = User.create!(
        name: name,
        email: email,
        primary_phone: normalized_phone,
        region: @region,
        region_id: region_id,
        password: temporary_password,
        password_confirmation: temporary_password,
        role: :cr
      )
      @person = Person.create!(
        region_id: region_id,
        org_id: org_id,
        user_id: @user.id
      )
      @patient = Patient.create!(
        person_id: @person.id,
        region_id: region_id,
        org_id: org_id,
        user_id: @user.id
      )
      @procedure = Procedure.create!(
        patient_id: @patient.id,
        person_id: @person.id,
        region_id: region_id,
        org_id: org_id,
        procedure_date: procedure_date,
        procedure_type: Procedure.procedure_types[procedure_type.gsub(' ', '_').downcase.to_sym],
        care_status: Procedure.care_statuses[:new_care_request]
      )
      true
    else
      false
    end
  end
end
