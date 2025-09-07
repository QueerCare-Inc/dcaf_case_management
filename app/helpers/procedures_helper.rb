# Functions primarily related to populating selects on procedures edit view.
module ProceduresHelper
  def procedure_type_options
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
     [t('common.other'),                                         'Other'],
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

  def clinic_options
    clinics = Clinic.all.sort_by(&:name)
    clinics.select(&:active)
           .map do |clinic|
      [
        t('procedure.information.clinic_display', clinic_name: clinic.name, city: clinic.city,
                                                  state: clinic.state),
        clinic.id,
        { data: {
          medicaid: !!clinic.accepts_medicaid,
          street_address: clinic.street_address,
          city: clinic.city,
          phone_number: clinic.phone_number,
          state: clinic.state,
          zip: clinic.zip
        } }
      ]
    end
                            .unshift nil

    # # Map inactives; if there are any, put in a breaker
    # inactive_clinics = clinics.reject(&:active)
    #                           .map { |clinic| [
    #                             t('patient.procedure_information.clinic_section.not_currently_working_with_fund', org: ActsAsTenant.current_tenant.name, clinic_name: clinic.name),
    #                             clinic.id,
    #                             { data: { medicaid: !!clinic.accepts_medicaid } }
    #                           ]}
    # if inactive_clinics.count > 0
    #   inactive_clinics.unshift ["--- #{t('patient.procedure_information.clinic_section.inactive_clinics').upcase} ---", nil, { disabled: true }]
    # end

    # | inactive_clinics
  end

  def surgeon_options
    surgeons = Surgeon.all.sort_by(&:name)
    surgeons.select(&:active)
            .map do |surgeon|
      [
        t('procedure.information.surgeon_display', surgeon_name: surgeon.name),
        surgeon.id
      ]
    end
                            .unshift nil
  end
end
