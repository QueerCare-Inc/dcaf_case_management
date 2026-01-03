module CareAddressHelper
  # Accessibility options for care addresses
  # These are checkboxes, so multiple can be selected
  # Stored as an array of strings in the DB
  # See app/models/care_address.rb
  def accessibility_options_list
    [
      [t('address.helper.accessibility.wheelchair_accessible'), 'Wheelchair accessible'],
      [t('address.helper.accessibility.shower_grab_bar'), 'Shower grab bar'],
      [t('address.helper.accessibility.other'), 'Other']
    ]
  end
end