FactoryBot.define do
  factory :call_list_entry do
    user
    patient
    region
    sequence :order_key
  end
end
