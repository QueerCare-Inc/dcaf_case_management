# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  # Defaults
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,

  # Custom
  :password,
  :email,
  :name,
  :age,
  :employment_status,
  :primary_phone,
  :secondary_phone,
  :city,
  :state,
  :zip,
  :procedure_date,
  :insurance,
  :street_address_1,
  :street_address_2,
  :shared_flag,
  :income,
  :special_circumstances,
  :in_case_of_emergency,
  :procedure_date,
  :procedure_completed_date,
  :household_size,
  :full_text,
  :search
]
