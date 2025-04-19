FactoryBot.define do
  factory :org do
    sequence :name do |n|
      "Org #{n}"
    end
    sequence :subdomain do |n|
      "org#{n}"
    end
    domain { 'example.com' }
    sequence :full_name do |n|
      "Org #{n} of Cat Town"
    end
    sequence :site_domain do |n|
      "www.org#{n}.pizza"
    end
    phone { '(939)-555-0113' }
  end
end
