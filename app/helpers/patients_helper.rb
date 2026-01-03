# Functions primarily related to populating selects on patient edit view.
require 'state_geo_tools'
module PatientsHelper
  def weeks_options
    (1..40).map { |i| [t('patient.helper.week', count: i), i] }.unshift [nil, nil]
  end

  def days_options
    (0..6).map { |i| [t('patient.helper.day', count: i), i] }.unshift [nil, nil]
  end

  def referred_by_options(current_value = nil)
    standard_options = [
      nil,
      [t('patient.helper.referred_by.clinic'),                       'Clinic'],
      # [t('patient.helper.referred_by.crime_victim_advocacy_center'), 'Crime victim advocacy center'],
      [t('patient.helper.referred_by.org', org: ActsAsTenant.current_tenant.name),
       "#{ActsAsTenant.current_tenant.name} website or social media"],
      # [t('patient.helper.referred_by.domestic_violence_org'),        'Domestic violence crisis/intervention org'],
      [t('patient.helper.referred_by.family'),                       'Family member'],
      [t('patient.helper.referred_by.friend'),                       'Friend'],
      [t('patient.helper.referred_by.web_search'),                   'Google/Web search'],
      [t('patient.helper.referred_by.homeless'),                     'Homeless shelter'],
      [t('patient.helper.referred_by.legal_clinic'),                 'Legal clinic'],
      # [t('patient.helper.referred_by.naf'),                          'NAF'],
      # [t('patient.helper.referred_by.nnaf'),                         'NNAF'],
      [t('patient.helper.referred_by.other_org'), 'Other org'],
      [t('patient.helper.referred_by.prev_patient'),                 'Previous patient'],
      [t('patient.helper.referred_by.school'),                       'School'],
      # [t('patient.helper.referred_by.sexual_assault_crisis_org'),    'Sexual assault crisis org'],
      [t('patient.helper.referred_by.youth'),                        'Youth outreach'],
      [t('common.prefer_not_to_answer'),                             'Prefer not to answer']
    ]
    full_set = Config.find_or_create_by(config_key: 'referred_by').options
    full_set.push(*standard_options) unless Config.hide_standard_dropdown?

    options_plus_current(full_set, current_value)
  end

  def insurance_options(current_value = nil)
    standard_options = [
      [t('patient.helper.insurance.none'), 'No insurance'],
      [t('patient.helper.insurance.unknown'), 'Don\'t know'],
      [t('common.prefer_not_to_answer'), 'Prefer not to answer'],
      [t('patient.helper.insurance.other'), 'Other (add to notes)']
    ]
    full_set = [nil] + Config.find_or_create_by(config_key: 'insurance').options
    full_set.push(*standard_options) unless Config.hide_standard_dropdown?

    options_plus_current(full_set, current_value)
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

  # TODO: revisit
  # def procedure_date_display(patient)
  #   return nil unless patient.procedure_date.present?

  #   day = patient.procedure_date.strftime('%m/%d/%Y')
  #   if patient.appointment_time
  #     time = patient.appointment_time.strftime('%l:%M %p').strip
  #     day = "#{day} @ #{time}"
  #   end
  #   day = "#{day} (#{t('patient.procedure_information.clinic_section.multi_day')})" if patient.multiday_appointment?
  #   day
  # end
end
