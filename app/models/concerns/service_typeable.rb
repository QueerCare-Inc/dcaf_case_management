# Methods pertaining to determining a patient's displayed status
module ServiceTypeable
  extend ActiveSupport::Concern

  SERVICES = {
    personal_care: { key: I18n.t('shift.service_type.key.personal_care'),
                     help_text: I18n.t('shift.service_type.help.personal_care') },
    meals: { key: I18n.t('shift.service_type.key.meals'),
             help_text: I18n.t('shift.service_type.help.meals') },
    chores: { key: I18n.t('shift.service_type.key.chores'),
              help_text: I18n.t('shift.service_type.help.chores') },
    grocery_shopping: { key: I18n.t('shift.service_type.key.grocery_shopping'),
                        help_text: I18n.t('shift.service_type.help.grocery_shopping') },
    prescriptions: { key: I18n.t('shift.service_type.key.prescriptions'),
                     help_text: I18n.t('shift.service_type.help.prescriptions') },
    transportation: { key: I18n.t('shift.service_type.key.transportation'),
                      help_text: I18n.t('shift.service_type.help.transportation') },
    companionship: { key: I18n.t('shift.service_type.key.companionship'),
                     help_text: I18n.t('shift.service_type.help.companionship') },
    other_service: { key: I18n.t('common.other'),
                     help_text: I18n.t('common.other') }
  }.freeze

  def service_type_texts
    stt = SERVICES[service_type.to_sym]
    stt if stt
  end

  def service_type_key_text
    stt = SERVICCES[service_type.to_sym]
    stt[:key] if stt
  end

  def service_type_help_text
    stt = SERVICES[service_type.to_sym]
    stt[:help] if stt
  end

  private
end
