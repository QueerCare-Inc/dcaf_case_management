FactoryBot.define do
  factory :region do
    sequence :name do |n|
      "Region#{n}"
    end
    org
  end
end
