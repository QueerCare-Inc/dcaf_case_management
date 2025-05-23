FactoryBot.define do
  factory :practical_support do
    patient
    sequence :source do |n|
      "Org #{n}"
    end
    sequence :support_type do |n|
      "Support #{n}"
    end
    confirmed { false }
    start_time { 2.days.from_now }
  end
end
