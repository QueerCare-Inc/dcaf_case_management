module PhoneCleanable
  extend ActiveSupport::Concern

  def clean_phone_number(phone_number)
    return nil if phone_number.nil?
    if phone_number[0] != '1' && phone_number.length == 10
      phone_number = "1#{phone_number}"
    end
    phone_number = phone_number.gsub(/\D/, '')
  end
end