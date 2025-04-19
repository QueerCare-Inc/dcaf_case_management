FactoryBot.define do
  factory :event do
    event_type { :reached_patient }
    care_coordinator_name { 'Yolorita' }
    patient_name { 'Susan Everyteen' }
    patient_id { 'sdfghjk' }
    region
  end
end
