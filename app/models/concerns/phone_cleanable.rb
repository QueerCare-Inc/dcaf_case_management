module PhoneCleanable
  extend ActiveSupport::Concern

  def clean_phone_number(phone_number)
    return nil if phone_number.nil?

    phone_number = "1#{phone_number}" if phone_number[0] != '1' && phone_number.length == 10
    phone_number = phone_number.gsub(/\D/, '')
  end

  def confirm_unique_phone_number(phone_number)
    ##
    # This method is preferred over Rail's built-in uniqueness validator
    # so that case managers get a meaningful error message when a patient
    # exists on a different region than the one the volunteer is serving.
    #
    # See https://github.com/DCAFEngineering/dcaf_case_management/issues/825
    ##
    phone_match = User.where(primary_phone: phone_number).first

    return unless phone_match
    # skip when an existing patient updates and matches itself
    return if phone_match.id == id

    users_region = phone_match.region
    volunteers_region = region
    if volunteers_region == users_region
      errors.add(:this_phone_number_is_already_taken, 'on this region.')
    else
      errors.add(:this_phone_number_is_already_taken,
                 "on the #{users_region.name} region. If you need the user's region changed, please contact the care coordinator directors.")
    end
  end

  def phone_number_display(phone_number)
    return nil unless phone_number.present?

    "#{phone_number[1..3]}-#{phone_number[4..6]}-#{phone_number[7..10]}"
  end
end
