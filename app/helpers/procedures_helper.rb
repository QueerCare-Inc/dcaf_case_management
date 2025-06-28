# Functions primarily related to populating selects on patient edit view.
module ProceduresHelper

  def procedure_options
    [nil,
    [t('procedure.helper.procedure_type.breast_augmentation'),  'Breast augmentation'],
    [t('procedure.helper.procedure_type.breast_reduction'),     'Breast reduction'],
    [t('procedure.helper.procedure_type.ffs'),                  'FFS'],
    [t('procedure.helper.procedure_type.fms'),                  'Facial masculinization'],
    [t('procedure.helper.procedure_type.hysterectomy'),         'Hysterectomy'],
    [t('procedure.helper.procedure_type.mastectomy'),           'Mastectomy'],
    [t('procedure.helper.procedure_type.metoidioplasty'),       'Metoidioplasty'],
    [t('procedure.helper.procedure_type.orchiectomy'),          'Orchiectomy'],
    [t('procedure.helper.procedure_type.phalloplasty'),         'Phalloplasty'],
    [t('procedure.helper.procedure_type.vaginoplasty'),         'Vaginoplasty'],
    [t('Common.other'),                                         'Other'],
    [t('common.prefer_not_to_answer'),                          'Prefer not to answer']]
  end

  # helper function for use with `options_for_select`
  # adds `current_value` to `options` if it's not already there
  #
  # call this at the _end_ of `*_options` functions, above, where we want to
  # prevent config clobbering (anything user-configurable)
  #
  # kinda ugly because we're working with a few different datatypes in here
  #   (arrays of strings, and strings)
  def options_plus_current(options, current_value = nil)
    if current_value.present? && options.map { |opt| opt.is_a?(Array) ? opt[-1] : opt }.exclude?(current_value)
      options.push current_value
    end

    options.uniq
  end

  def region_options
    Region.all.sort_by(&:name).map { |x| [x.name, x.id] }
  end
end