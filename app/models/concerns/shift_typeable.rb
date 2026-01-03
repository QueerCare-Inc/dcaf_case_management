# Methods pertaining to determining a patient's displayed status
module ShiftTypeable
  extend ActiveSupport::Concern

  SHIFTS = {
    in_home: { key: I18n.t('shift.shift_type.key.in_home'),
               help_text: I18n.t('shift.shift_type.help.in_home') },
    errands: { key: I18n.t('shift.shift_type.key.errands'),
               help_text: I18n.t('shift.shift_type.help.errands') },
    transportation: { key: I18n.t('shift.shift_type.key.transportation'),
                      help_text: I18n.t('shift.shift_type.help.transportation') },
    virtual: { key: I18n.t('shift.shift_type.key.virtual'),
               help_text: I18n.t('shift.shift_type.help.virtual') },
    other_shift: { key: I18n.t('common.other'),
                   help_text: I18n.t('common.other') },
    overnight: { key: I18n.t('shift.shift_type.key.overnight'),
                 help_text: I18n.t('shift.shift_type.help.overnight') }
  }.freeze

  def shift_type_texts
    stt = SHIFTS[shift_type.to_sym]
    stt if stt
  end

  def shift_type_key_text
    stt = SHIFTS[shift_type.to_sym]
    stt[:key] if stt
  end

  def shift_type_help_text
    stt = SHIFTS[shift_type.to_sym]
    stt[:help] if stt
  end

  private
end
