# Methods pertaining to determining a patient's displayed status
module UserRoleable
  extend ActiveSupport::Concern

  ROLES = {
    care_coordinator: { key: I18n.t('user.roleable_types.key.care_coordinator') },
    data_volunteer: { key: I18n.t('user.roleable_types.key.data_volunteer') },
    admin: { key: I18n.t('user.roleable_types.key.admin') },
    cr: { key: I18n.t('user.roleable_types.key.cr') },
    volunteer: { key: I18n.t('user.roleable_types.key.volunteer') },
    finance_admin: { key: I18n.t('user.roleable_types.key.finance_admin') },
    coord_admin: { key: I18n.t('user.roleable_types.key.coord_admin') }
  }.freeze

  def user_role_texts
    stt = ROLES[role.to_sym]
    stt if stt
  end

  def user_role_key_text
    stt = ROLES[role.to_sym]
    stt[:key] if stt
  end

  def user_role_help_text
    stt = ROLES[role.to_sym]
    stt[:help] if stt
  end

  private
end
