# Methods pertaining to determining a patient's displayed status
module Statusable
  extend ActiveSupport::Concern

  STATUSES = {
    no_contact: { key: I18n.t('patient.status.key.no_contact'),
                  help_text: I18n.t('patient.status.help.no_contact') },
    needs_appt: { key: I18n.t('patient.status.key.needs_appt'),
                  help_text: I18n.t('patient.status.help.needs_appt') },
    fundraising: { key: I18n.t('patient.status.key.fundraising'),
                   help_text: I18n.t('patient.status.help.fundraising') },
    fulfilled: { key: I18n.t('patient.status.key.fulfilled'),
                 help_text: I18n.t('patient.status.help.fulfilled') },
    dropoff: { key: I18n.t('patient.status.key.dropoff'),
               help_text: I18n.t('patient.status.help.dropoff') },
    resolved: { key: I18n.t('patient.status.key.resolved', fund: ActsAsTenant.current_tenant&.name),
                help_text: I18n.t('patient.status.help.resolved') }
  }.freeze

  def status
    return STATUSES[:fulfilled][:key] if fulfillment.fulfilled?
    return STATUSES[:dropoff][:key] if days_since_last_call > 120
    return STATUSES[:no_contact][:key] unless contact_made?
    return STATUSES[:fundraising][:key] if appointment_date

    STATUSES[:needs_appt][:key]
  end

  private

  def contact_made?
    calls.each do |call|
      return true if call.reached_patient?
    end
    false
  end

  def days_since_last_call
    return 0 if calls.blank?

    (DateTime.now.in_time_zone.to_date - last_call.created_at.to_date).to_i
  end
end
