# Fields used in the result table will vary, so...
module ClinicfindersHelper
  def parse_clinicfinder_field(clinic, field)
    case field
    when :location
      t 'clinic_locator.result.location', city: clinic.city, state: clinic.state
    when :distance
      t 'clinic_locator.result.distance', miles: clinic[field].round(2)
    when :cost
      number_to_currency clinic[field], precision: 0
    else
      clinic[field]
    end
  end
end
