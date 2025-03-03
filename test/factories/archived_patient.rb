FactoryBot.define do
  factory :archived_patient do
    region
    intake_date { 400.days.ago }
  end
end
