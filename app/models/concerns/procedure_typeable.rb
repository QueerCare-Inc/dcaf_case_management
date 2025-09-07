# Methods pertaining to determining a patient's displayed status
module ProcedureTypeable
  extend ActiveSupport::Concern

  STATUSES = {
    not_specified: { key: I18n.t('common.not_specified'),
                  help_text: I18n.t('common.not_specified') },
    mastectomy: { key: I18n.t('procedure.procedure_type.key.mastectomy'),
                  help_text: I18n.t('procedure.procedure_type.help.mastectomy') },
    breast_augmentation: { key: I18n.t('procedure.procedure_type.key.breast_augmentation'),
                   help_text: I18n.t('procedure.procedure_type.help.breast_augmentation') },
    breast_reduction: { key: I18n.t('procedure.procedure_type.key.breast_reduction'),
                 help_text: I18n.t('procedure.procedure_type.help.breast_reduction') },
    hysterectomy: { key: I18n.t('procedure.procedure_type.key.hysterectomy'),
               help_text: I18n.t('procedure.procedure_type.help.hysterectomy') },
    orchiectomy: { key: I18n.t('procedure.procedure_type.key.orchiectomy'),
               help_text: I18n.t('procedure.procedure_type.help.orchiectomy') },
    vaginectomy: { key: I18n.t('procedure.procedure_type.key.vaginectomy'),
               help_text: I18n.t('procedure.procedure_type.help.vaginectomy') },
    metoidioplasty: { key: I18n.t('procedure.procedure_type.key.metoidioplasty'),
               help_text: I18n.t('procedure.procedure_type.help.metoidioplasty') },
    vaginoplasty: { key: I18n.t('procedure.procedure_type.key.vaginoplasty'),
               help_text: I18n.t('procedure.procedure_type.help.vaginoplasty') },
    phalloplasty: { key: I18n.t('procedure.procedure_type.key.phalloplasty'),
               help_text: I18n.t('procedure.procedure_type.help.phalloplasty') },
    facial_feminization: { key: I18n.t('procedure.procedure_type.key.ffs'),
               help_text: I18n.t('procedure.procedure_type.help.ffs') },
    facial_masculinization: { key: I18n.t('procedure.procedure_type.key.fms'),
               help_text: I18n.t('procedure.procedure_type.help.fms') },
    other: { key: I18n.t('common.other'),
               help_text: I18n.t('common.other') }
  }.freeze

  def procedure_type_texts
    ptt = STATUSES[procedure_type.to_sym]
    return ptt if ptt
  end
  
  def procedure_type_key_text
    ptt = STATUSES[procedure_type.to_sym]
    return ptt[:key] if ptt 
  end

  def procedure_type_help_text
    ptt = STATUSES[procedure_type.to_sym]
    return ptt[:help] if ptt 
  end

  private

end