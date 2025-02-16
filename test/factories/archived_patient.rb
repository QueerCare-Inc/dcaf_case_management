FactoryBot.define do
  factory :archived_patient do
    line
  intake_date { 400.days.ago }
  end
end
