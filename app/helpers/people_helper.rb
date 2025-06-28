# Functions primarily related to populating selects on patient edit view.
require 'state_geo_tools'
module PeopleHelper
  def weeks_options
    (1..40).map { |i| [t('person.helper.week', count: i), i] }.unshift [nil, nil]
  end

  def days_options
    (0..6).map { |i| [t('person.helper.day', count: i), i] }.unshift [nil, nil]
  end

  def race_ethnicity_options
    [nil,
     [t('person.helper.race.white_caucasian'),                  'White/Caucasian'],
     [t('person.helper.race.black_african_american'),           'Black/African-American'],
     [t('person.helper.race.hispanic_latino'),                  'Hispanic/Latino'],
     [t('person.helper.race.asian_south_asian'),                'Asian or South Asian'],
     [t('person.helper.race.native_hawaiian_pacific_islander'), 'Native Hawaiian or Pacific Islander'],
     [t('person.helper.race.native_american'),                  'Native American'],
     [t('person.helper.race.mixed_race_ethnicity'),             'Mixed Race/Ethnicity'],
     [t('person.helper.race.other'),                            'Other'],
     [t('common.prefer_not_to_answer'), 'Prefer not to answer']]
  end

  # TODO: how to i18n the Config?
  def language_options(current_value = nil)
    standard_options = [[t('person.helper.language.English'), nil]]
    # NOTE: don't check hide_standard_dropdown? here because we always want
    # English to be available.
    full_set = standard_options + Config.find_or_create_by(config_key: 'language').options

    options_plus_current(full_set, current_value)
  end

  def voicemail_options(current_value = nil)
    standard_options = [
      [t('dashboard.helpers.voicemail_options.not_specified'), 'not_specified'],
      [t('dashboard.helpers.voicemail_options.no'), 'no'],
      [t('dashboard.helpers.voicemail_options.yes'), 'yes']
    ]
    full_set = Config.find_or_create_by(config_key: 'voicemail').options

    # voicemail also exempt from hide_standard_dropdown? config
    full_set.push(*standard_options)

    options_plus_current(full_set, current_value)
  end

  def employment_status_options
    [
      nil,
      [t('person.helper.employment.full_time'), 'Full-time'],
      [t('person.helper.employment.part_time'), 'Part-time'],
      [t('person.helper.employment.unemployed'), 'Unemployed'],
      [t('person.helper.employment.odd_jobs'), 'Odd jobs'],
      [t('person.helper.employment.student'), 'Student'],
      [t('common.prefer_not_to_answer'), 'Prefer not to answer']
    ]
  end

  def income_options
    [nil,
     [t('person.helper.income.under_10'), 'Under $9,999'],
     [t('person.helper.income.10_to_15'), '$10,000-14,999'],
     [t('person.helper.income.15_to_20'), '$15,000-19,999'],
     [t('person.helper.income.20_to_25'), '$20,000-24,999'],
     [t('person.helper.income.25_to_30'), '$25,000-29,999'],
     [t('person.helper.income.30_to_35'), '$30,000-34,999'],
     [t('person.helper.income.35_to_40'), '$35,000-39,999'],
     [t('person.helper.income.40_to_45'), '$40,000-44,999'],
     [t('person.helper.income.45_to_50'), '$45,000-49,999'],
     [t('person.helper.income.50_to_60'), '$50,000-59,999'],
     [t('person.helper.income.60_to_75'), '$60,000-74,999'],
     [t('person.helper.income.75_plus'), '$75,000 or more'],
     [t('common.prefer_not_to_answer'), 'Prefer not to answer']]
  end

  def county_options(current_value = nil)
    county_options = Config.find_or_create_by(config_key: 'county').options

    return [] if county_options.blank?

    options_plus_current([nil] + county_options, current_value)
  end

  def household_size_options
    (0..10).map { |i| i }
           .unshift([t('common.prefer_not_to_answer'), -1])
           .unshift([nil, nil])
  end

  def state_options(current_state)
    StateGeoTools.state_codes.map { |code| [code, code] }.unshift([nil, nil])
                 .push([current_state, current_state]).uniq
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
