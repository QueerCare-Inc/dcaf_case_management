namespace :db do
  namespace :seed do
    desc 'Generate 20 training accounts - training-account-n@example.com'
    task :training => :environment do
      fail 'No running seeds in prod' unless [nil, 'Sandbox'].include? ENV['DARIA_ORG']

      # Create two test users
      20.times do |i|
        User.create! name: "Training Account #{i}",
                     email: "training-account-#{i}@example.com",
                     password: "AbortionsAreAHumanRight1",
                     password_confirmation: "AbortionsAreAHumanRight1"
      end 
    end
  end
end
