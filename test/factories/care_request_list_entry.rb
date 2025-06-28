FactoryBot.define do
  factory :care_request_list_entry do
    user
    patient
    region
    procedure
    care_coordinator
    sequence :procedure_date # :order_key
  end
end
