# Methods related to displaying attributes on the patient model
module AttributeDisplayable
  extend ActiveSupport::Concern

  # def primary_phone_display
  #   return nil unless primary_phone.present?
  #   "#{primary_phone[0..2]}-#{primary_phone[3..5]}-#{primary_phone[6..9]}"
  # end

  # def emergency_contact_phone_display
  #   return nil unless emergency_contact_phone.present?
  #   "#{emergency_contact_phone[0..2]}-#{emergency_contact_phone[3..5]}-#{emergency_contact_phone[6..9]}"
  # end

  def procedure_date_display
    return nil unless procedure_date.present?
    "#{procedure_date}"
  end

  def procedure_type_display
    return nil unless procedure_type.present?
    t("procedure.helper.procedure_type.#{procedure_type.downcase.gsub(' ', '_')}")
  end

  def surgeon_display
    surgeon = Surgeon.find_by(id: surgeon_id)
    return nil unless surgeon.present?
    surgeon.name
  end

  def clinic_display
    clinic = Clinic.find_by(id: clinic_id)
    return nil unless clinic.present?
    clinic.name
  end

  def support_dates_display
    return nil unless service_start.present? && service_end.present?
    "#{service_start} - #{service_end}"
  end

  # def email_display
  #   return nil unless email.present?
  #   "#{email}"
  # end
end
