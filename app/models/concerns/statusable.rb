# Methods pertaining to determining a patient's displayed status
module Statusable
  extend ActiveSupport::Concern

  STATUSES = {
    rejected_care_request: { key: I18n.t('procedure.care_status.key.rejected_care_request'),
                             help_text: I18n.t('procedure.care_status.help.rejected_care_request') },
    archived: { key: I18n.t('procedure.care_status.key.archived'),
                help_text: I18n.t('procedure.care_status.help.archived') },
    new_care_request: { key: I18n.t('procedure.care_status.key.new_care_request'),
                        help_text: I18n.t('procedure.care_status.help.new_care_request') },
    coordinator_assigned: { key: I18n.t('procedure.care_status.key.coordinator_assigned'),
                            help_text: I18n.t('procedure.care_status.help.coordinator_assigned') },
    intake_complete: { key: I18n.t('procedure.care_status.key.intake_complete'),
                       help_text: I18n.t('procedure.care_status.help.intake_complete') },
    accepted_care_request: { key: I18n.t('procedure.care_status.key.accepted_care_request'),
                             help_text: I18n.t('procedure.care_status.help.accepted_care_request') },
    procedure_confirmed: { key: I18n.t('procedure.care_status.key.procedure_confirmed'),
                           help_text: I18n.t('procedure.care_status.help.procedure_confirmed') },
    under_care: { key: I18n.t('procedure.care_status.key.under_care'),
                  help_text: I18n.t('procedure.care_status.help.under_care') },
    care_complete: { key: I18n.t('procedure.care_status.key.care_complete'),
                     help_text: I18n.t('procedure.care_status.help.care_complete') }
  }.freeze

  # def status
  #   return STATUSES[:fulfilled][:key] if fulfillment.fulfilled?
  #   return STATUSES[:dropoff][:key] if days_since_last_call > 120
  #   return STATUSES[:no_contact][:key] unless contact_made?
  #   return STATUSES[:fundraising][:key] if procedure_date

  #   STATUSES[:needs_appt][:key]
  # end

  def status_texts(care_status)
    status = STATUSES[care_status.to_sym]
    status if status
  end

  def status_key_text(care_status)
    status = STATUSES[care_status.to_sym]
    status[:key] if status
  end

  def status_help_text(care_status)
    status = STATUSES[care_status.to_sym]
    status[:help] if status
  end

  private

  # def contact_made?
  #   calls.each do |call|
  #     return true if call.reached_patient?
  #   end
  #   false
  # end

  # def days_since_last_call
  #   return 0 if calls.blank?

  #   (DateTime.now.in_time_zone.to_date - last_call.created_at.to_date).to_i
  # end
end
