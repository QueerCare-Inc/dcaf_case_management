namespace :db do
  namespace :seed do
    desc 'Generate fake patient entries for data wranglers'
    task :create_fake_data => :environment do

        ActsAsTenant.current_tenant = Fund.first
        users = User.all
        clinics = Clinic.all

        gen = Random.new(2020) # our random number generator: https://ruby-doc.org/core-2.7.0/Random.html

        5000.times do |idx|
          idx % 10 == 0 ? print("\nMaking fake pt #{idx} of 5000") : print('.')
          flag = gen.rand < 0.05 # gen.rand will always return a float between 0 and 1 

          initial_call = Date.today - gen.rand(300)
          
          has_appt = gen.rand < 0.8

          regions = Region.all # need to add Spanish maybe? 

          patient = Patient.create!(
            name: 'Randomized Patient',
            primary_phone: "#{idx}".rjust(10, "0"),
            intake_date: initial_call,
            created_by: users.sample,
            shared_flag: flag,
            region: regions[gen.rand(3)], # thank you seeds.rb! 
            clinic: has_appt ? clinics.sample : nil,
            appointment_date: has_appt ? initial_call + gen.rand(15) : nil
          )

          # create calls, where every patient will have at least one call made
          call_status = [:left_voicemail, :reached_patient, :couldnt_reach_patient]

          gen.rand(1..7).times do
            patient.calls.create status: call_status[gen.rand(3)], created_by: users.sample
          end
          
          # create practical_support
          support_types = [
            'Companion', 
            'Lodging', 
            'Travel to the region', 
            'Travel inside the region', 
            'Other (see notes)']
          
          if has_appt
            patient.practical_supports.create!(
              source: 'Metallica Abortion Fund',
              support_type: support_types[gen.rand(5)],
              created_by: users.sample
            )
          end 
          
        end

        puts "Fake patients created! The database now has #{Patient.count} patients."

    end   
  end
end
