# Set up fixtures and database seeds to simulate a production environment.
raise "No running seeds in prod" unless [nil, "Sandbox"].include? ENV["DARIA_FUND"]

# Clear out existing DB
ActsAsTenant.without_tenant do
  Config.destroy_all
  Event.destroy_all
  Call.destroy_all
  CallListEntry.destroy_all
  Fulfillment.destroy_all
  Note.destroy_all
  Patient.destroy_all
  ArchivedPatient.destroy_all
  Volunteer.destroy_all
  CareCoordinator.destroy_all
  Person.destroy_all
  User.destroy_all
  Clinic.destroy_all
  PaperTrailVersion.destroy_all
  ActiveRecord::SessionStore::Session.destroy_all
  Region.destroy_all
  Org.destroy_all
  CareAddress.destroy_all
  QcHousing.destroy_all
  Procedure.destroy_all
  Shift.destroy_all
  Surgeon.destroy_all
  Reimbursement.destroy_all
end

# Do versioning
PaperTrail.enabled = true

# Set a few config constants
note_text = "This is a note " * 10
additional_note_text = "Additional note " * 10
password = "AbortionsAreAHumanRight1"

# Create a few test orgs
org1 = Org.create!(
        name: "SBF",
        domain: "petfinder.com",
        subdomain: "sandbox",
        full_name: "Sand Box Fund",
        site_domain: "www.petfinder.com",
        phone: "202-452-7464"
)

org2 = Org.create!(
        name: "CatFund",
        domain: "petfinder.com",
        subdomain: "catbox",
        full_name: "Cat Fund",
        site_domain: "www.petfinder.com",
        phone: "(281) 330-8004"
)

[org1, org2].each do |org|
  ActsAsTenant.with_tenant(org) do
    regions = if org == org1
              ["Main", "Spanish"].map { |region| Region.create! name: region }
            else
              ["Maru", "Guremike"].map { |region| Region.create! name: region }
            end

    # Create test users
    admin_user = User.create!(
                  name: "testuser (admin)", 
                  email: "test@example.com",
                  primary_phone: "456-123-1231", 
                  region: regions.first,
                  region_id: regions.first.id,
                  password: password, 
                  password_confirmation: password,
                  role: :admin
    )

    cc_user1 = User.create!(
                  name: "testuser two", 
                  email: "test2@example.com",
                  primary_phone: "456-123-1232", 
                  region: regions.first,
                  region_id: regions.first.id,
                  password: password, 
                  password_confirmation: password,
                  role: :care_coordinator
    )
    cc_user2 = User.create!(
                  name: "testuser three", 
                  email: "test3@example.com",
                  primary_phone: "456-123-1233", 
                  region: regions.second,
                  region_id: regions.second.id,
                  password: password, 
                  password_confirmation: password,
                  role: :care_coordinator
    )

    # finance_user = User.create! name: "testuser five",
    #                       email: "test5@example.com",
    #                       primary_phone: "456-123-1235", 
    #                       region: regions.second,
    #                       password: password, 
    #                       password_confirmation: password,
    #                       role: :finance_admin

    # cc_admin_user = User.create! name: "testuser six", 
    #                       email: "test6@example.com",
    #                       primary_phone: "456-123-1236", 
    #                       region: regions.first,
    #                       password: password, 
    #                       password_confirmation: password,
    #                       role: :coord_admin

    # create people for different users
    cc_person1 = cc_user1.create_new_person

    cc_person2 = cc_user2.create_new_person

    care_coordinator2 = cc_person1.create_new_care_coordinator
    care_coordinator2.update!(
      volunteer_types: ["remote", "transportation"]
    )
                  
    care_coordinator3 = cc_person2.create_new_care_coordinator
    care_coordinator3.update!(
      volunteer_types: ["transportation", "in-person"]
    )
                  
    # Default to cc_user1 as the actor
    PaperTrail.request.whodunnit = cc_user1.id

    # Create a few clinics
    Clinic.create!(
      name: "Sample Clinic 1 - DC", 
      street_address: "1600 Pennsylvania Ave",
      city: "Washington", state: "DC", zip: "20500",
      region_id: regions.first.id
    )
    Clinic.create!(
      name: "Sample Clinic 2 - VA", 
      street_address: "1400 Defense",
      city: "Arlington", state: "VA", zip: "20301",
      region_id: regions.second.id
    )
    Clinic.create!(
      name: "Sample Clinic with NAF", 
      street_address: "815 V Street NW",
      city: "Washington", state: "DC", zip: "20001",
      region_id: regions.first.id
    )
    Clinic.create!(
      name: "Sample Clinic without NAF", 
      street_address: "1811 14th Street NW",
      city: "Washington", state: "DC", zip: "20009", accepts_medicaid: true,
      region_id: regions.second.id
    )

    # Create user-settable configuration
    Config.create(
      config_key: :insurance,
      config_value: { options: ["DC Medicaid", "MD Medicaid", "VA Medicaid", "Other Insurance"] }
    )
    Config.create(
      config_key: :language,
      config_value: { options: %w[Spanish French Korean] }
    )
    Config.create(
      config_key: :resources_url,
      config_value: { options: ["https://www.petfinder.com/cats/"] }
    )
    Config.create(
      config_key: :practical_support_guidance_url,
      config_value: { options: ["https://www.petfinder.com/dogs/"] }
    )
    Config.create(
      config_key: :referred_by,
      config_value: { options: ["Metal band"] }
    )
    Config.create(
      config_key: :fax_service,
      config_value: { options: ["https://www.efax.com"] }
    )
    Config.create(
      config_key: :start_of_week,
      config_value: { options: ["Monday"] }
    )
    
    # Create ten active patients with generic info.
    10.times do |i|
      cr_user = User.create!(
                  name: "testuser patient", 
                  email: "test_p#{i}@example.com",
                  primary_phone: "123-123-123#{i}", 
                  region: regions.first,
                  region_id: regions.first.id,
                  password: password, 
                  password_confirmation: password,
                  role: :cr
      )
      cr_person = cr_user.create_new_person
      
      patient = cr_person.create_new_patient
      patient.update!(
        intake_date: 3.days.ago,
        shared_flag: i.even?
      )
      
      # Create associated objects
      case i
      when 0
        10.times do
          patient.calls.create!(
            status: :reached_patient,
            created_at: 3.days.ago
          )
        end
      when 1
        PaperTrail.request(whodunnit: admin_user.id) do
          cr_user.update!(name: "Other Contact info - one")
          cr_person.update!(
              emergency_contact: "Jane Doe",
              emergency_contact_phone: "234-456-6789", 
              emergency_contact_relationship: "Sister"
          )
                          
          patient.calls.create!(
              status: :reached_patient,
              created_at: 14.hours.ago
          )
        end
      # when 2 #TODO: create other test cases
      #   # appointment one week from today && clinic selected
      #   cr_user.update!(
      #     name: "Clinic and Appt - two",
      #     pronouns: "she/they"
      #   )
                        
      #   cr_person.update!(zipcode: "20009")
                      
      #   patient.update!(
      #     clinic: Clinic.first
      #     # procedure_date: 2.days.from_now
      #   )
      when 4
        PaperTrail.request(whodunnit: admin_user.id) do
          # With special circumstances
          cr_user.update!(name: "Special Circumstances - four")
          cr_person.update!(special_circumstances: ["Prison", "Fetal anomaly"])
          # And a recent call on file
          patient.calls.create!(status: :left_voicemail)
        end
      end

      if i != 9
        5.times do
          patient.calls.create!(
            status: :left_voicemail,
            created_at: 3.days.ago
          )
        end
      end

      # Add notes for most patients
      unless [0, 1].include? i
        patient.notes.create!(full_text: note_text)
      end

      if i.even?
        patient.notes.create!(full_text: additional_note_text)
        # patient.practical_supports.create! support_type: "Advice", source: "Counselor", start_time: (Time.now + rand(10).days), end_time: (Time.now - rand(10).days + 4.hours)
      end

      # if i % 3 == 0
      #   patient.practical_supports.create! support_type: "Car rides", source: "Neighbor", 
      #                                       start_time: 3.days.from_now, end_time: 4.days.from_now
      # end

      # if i % 5 == 0
      #   patient.practical_supports.create! support_type: "Hotel", source: "Donation", amount: 100
      # end

      # # Add select patients to call list for cc_user1
      # cc_user1.add_patient patient if [0, 1, 2, 3, 4, 5].include? i

      patient.save
    end

    # # Add patients for reporting purposes - CSV exports, fulfillments, etc.
    # PaperTrail.request.whodunnit = admin_user.id
    # 10.times do |i|
    #   patient = Patient.create!(
    #     name: "Reporting Patient #{i}",
    #     primary_phone: "321-0#{i}0-001#{rand(10)}",
    #     intake_date: 3.days.ago,
    #     shared_flag: i.even?,
    #     region: i.even? ? regions.first : regions.second,
    #     clinic: Clinic.all.sample,
    #     procedure_date: 10.days.from_now,
        
    #   )

    #   next unless i.even?

    #   patient.fulfillment.update fulfilled: true,
    #                              procedure_date: 10.days.from_now
    # end

    # (1..5).each do |patient_number|
    #   patient = Patient.create!(
    #     name: "Reporting Patient #{patient_number}",
    #     primary_phone: "321-0#{patient_number}0-002#{rand(10)}",
    #     intake_date: 3.days.ago,
    #     shared_flag: patient_number.even?,
    #     region: regions[patient_number % 3] || regions.first,
    #     clinic: Clinic.all.sample,
    #     procedure_date: 10.days.from_now
    #   )

    #   # reached within the past 30 days
    #   5.times do
    #     patient.calls.create! status: :reached_patient,
    #                           created_at: (Time.now - rand(10).days)
    #     patient.calls.create! status: :reached_patient,
    #                           created_at: (Time.now - rand(10).days - 10.days)
    #   end
    # end

    # (1..5).each do |patient_number|
    #   patient = Patient.create!(
    #     name: "Old Reporting Patient #{patient_number}",
    #     primary_phone: "321-0#{patient_number}0-003#{rand(10)}",
    #     intake_date: 3.days.ago,
    #     shared_flag: patient_number.even?,
    #     region: regions[patient_number % 3] || regions.first,
    #     clinic: Clinic.all.sample,
    #     procedure_date: 10.days.from_now
    #   )

    #   5.times do
    #     patient.calls.create! status: :reached_patient,
    #                           created_at: (Time.now - rand(10).days - 6.months)
    #   end
    # end

    # (1..5).each do |patient_number|
    #   Patient.create!(
    #     name: "Pledge Reporting Patient #{patient_number}",
    #     primary_phone: "321-0#{patient_number}0-004#{rand(10)}",
    #     intake_date: 3.days.ago,
    #     shared_flag: patient_number.even?,
    #     region: regions[patient_number % 3] || regions.first,
    #     clinic: Clinic.all.sample,
    #     procedure_date: 10.days.from_now,

    #   )
    # end

    # Add patients for archiving purposes with ALL THE INFO
    (1..2).each do |patient_number|
      # initial create data from voicemail
      cr_user = User.create!(
                  name: "Archive Dataful Patient", 
                  email: "test_adp#{patient_number}@example.com",
                  primary_phone: "321-0#{patient_number}0-005#{rand(10)}", 
                  region: regions.first,
                  region_id: regions.first.id,
                  password: password, 
                  password_confirmation: password,
                  role: :cr,
                  pronouns: "they/he"
      )
      cr_person = cr_user.create_new_person
      cr_person.update!(
        language: "Spanish"
      )
      patient = cr_person.create_new_patient
      patient.update!(
        voicemail_preference: "yes",
        intake_date: 140.days.ago,
        created_at: 140.days.ago
      )

      # Call, but no answer. leave a VM.
      patient.calls.create(status: :left_voicemail, created_at: 139.days.ago)

      # Call, which updates patient info, maybe flags shared, make a note.
      patient.calls.create(status: :reached_patient, created_at: 138.days.ago)

      patient.update!(
        # procedure_date: 130.days.ago,
        # clinic: Clinic.all.sample,
        referred_to_clinic: patient_number.odd?,
        updated_at: 139.days.ago # not sure if this even works?
      )
      cr_person.update!(
        age: 24,
        race_ethnicity: "Hispanic/Latino",
        city: "Washington",
        state: "DC",
        emergency_contact: "Susie Q.",
        emergency_contact_phone: "555-0#{patient_number}0-0053",
        emergency_contact_relationship: "Mother",
        employment_status: "Student",
        income: "$10,000-14,999",
        household_size_adults: 3,
        household_size_children: 2,
        special_circumstances: ["", "", "Homelessness", "", "", "Other medical issue", "", "", ""],
        updated_at: 138.days.ago # not sure if this even works?
      )

      # toggle shared flag, maybe
      patient.update!(
        insurance: "Other Insurance",
        referred_by: "Clinic",
        shared_flag: patient_number.odd?,
        updated_at: 137.days.ago
      )

      # generate notes
      patient.notes.create!(
        full_text: "One note, with iffy PII! This one was from the first call!",
        created_at: 137.days.ago
      )

      # another call. get abortion information, create pledges, a note.
      patient.calls.create!(status: :reached_patient, created_at: 136.days.ago)

      # notes tab
      PaperTrail.request(whodunnit: cc_user1.id) do
        patient.notes.create!(
          full_text: "Two note, maybe with iffy PII! From the second call.",
          created_at: 133.days.ago
        )
      end

      # fulfillment
      patient.fulfillment.update!(
        fulfilled: true,
        # procedure_date: 130.days.ago,
        updated_at: 125.days.ago
      )
    end

    (1..2).each do |patient_number|
      # Create dropoff patients
      cr_user = User.create!(
                  name: "Archive Dropoff Patient", 
                  email: "test_adrp#{patient_number}@example.com",
                  primary_phone: "867-9#{patient_number}0-004#{rand(10)}", 
                  region: regions.first,
                  region_id: regions.first.id,
                  password: password, 
                  password_confirmation: password,
                  role: :cr,
                  pronouns: "they/he"
      )
      cr_person = cr_user.create_new_person
      cr_person.update!(
        language: "Spanish"
      )
      patient = cr_person.create_new_patient
      patient.update!(
        voicemail_preference: "yes",
        intake_date: 640.days.ago,
        created_at: 640.days.ago
      )

      # Call, but no answer. leave a VM.
      patient.calls.create(status: :left_voicemail, created_at: 639.days.ago)

      # Call, which updates patient info, maybe flags, make a note.
      patient.calls.create(status: :reached_patient, created_at: 138.days.ago)

      # Patient 1 drops off immediately
      next if patient_number.odd?

      # We reach Patient 2
      patient.update!(
        # header info - hand filled in
        # procedure_date: 630.days.ago,
        insurance: "Other Insurance",
        referred_by: "Clinic",
        # abortion info - hand filled in
        # clinic: Clinic.all.sample,
        referred_to_clinic: patient_number.odd?
      )
      cr_user.update!(
        pronouns: "they/them"
      )
      cr_person.update!(
        # patient info - hand filled in
        age: 24,
        race_ethnicity: "Hispanic/Latino",
        city: "Washington",
        state: "DC",
        zipcode: "20009",
        emergency_contact: "Susie Q.",
        emergency_contact_phone: "555-6#{patient_number}0-0053",
        emergency_contact_relationship: "Mother",
        employment_status: "Student",
        income: "$10,000-14,999",
        household_size_adults: 3,
        household_size_children: 2,
        special_circumstances: ["", "", "Homelessness", "", "", "Other medical issue", "", "", ""]
      )

      # toggle flag, maybe
      patient.update!(
        shared_flag: patient_number.odd?,
        updated_at: 637.days.ago
      )

      # generate notes
      patient.notes.create!(
        full_text: "One note, with iffy PII! This one was from the first call!",
        created_at: 637.days.ago
      )
    end

    # A few specific named cases that reflect common scenarios
    cr_user = User.create!(
                name: "Regina", 
                email: "regina@example.com",
                primary_phone: "000-000-0001", 
                region: regions.first,
                region_id: regions.first.id,
                password: password, 
                password_confirmation: password,
                role: :cr,
                pronouns: "they/she"
    )
    cr_person = cr_user.create_new_person
    regina = cr_person.create_new_patient
    regina.update!(
      intake_date: 30.days.ago
    )
    regina.calls.create!(
      created_at: 30.days.ago,
      status: "reached_patient"
    )
    # regina.update(
    #   # procedure_date: 18.days.ago,
    #   # clinic: Clinic.first
    # )

    regina.calls.create!(
      created_at: 22.days.ago,
      status: "reached_patient"
    )
    regina.fulfillment.update(
      fulfilled: true,
      # procedure_date: 18.days.ago
    )

    regina.notes.create!(full_text: "SCENARIO: Regina calls us at 6 weeks LMP on 3-12. We call her back and reach the patient. We explain the org's policies of only funding after 7 weeks LMP. Regina’s options are to either schedule her appointment a week from the day she calls or org her procedure on her own. We offer her references to clinics who will be able to see her and the number to other funders who may be able to help her. We emphasize although we cannot org her now financially, we can in the future and she should call us back if that is the case. She says she will make an appointment for two weeks out. Regina calls us back on 3-20. Her funding is completed. We send the pledge to the clinic on Regina's behalf. Regina goes to her appointment on 3-24 and has her abortion. The clinic mails us back the completed pledge form on 4-15. Org checks the pledge against our system, completes an entry in our ledger, notes the completed pledge on Regina's file in DARIA (which then anon’s her data eventually), writes a check to the clinic and mails the check it to the clinic.")

    cr_user = User.create!(
                name: "Janis", 
                email: "janis@example.com",
                primary_phone: "000-000-0002", 
                region: regions.first,
                region_id: regions.first.id,
                password: password, 
                password_confirmation: password,
                role: :cr,
                pronouns: "she/they"
    )
    cr_person = cr_user.create_new_person
    janis = cr_person.create_new_patient
    janis.update!(
      intake_date: 40.days.ago
    ) 
    
    janis.calls.create!(
      created_at: 40.days.ago,
      status: "left_voicemail"
    )
    janis.calls.create!(
      created_at: 40.days.ago,
      status: "left_voicemail"
    )
    janis.calls.create!(
      created_at: 39.days.ago,
      status: "left_voicemail"
    )
    janis.calls.create!(
      created_at: 40.days.ago,
      status: "couldnt_reach_patient"
    )
    janis.notes.create(full_text: "SCENARIO: Janis calls us on 6-17. We call her back and leave a voicemail. We try again at the end of the night, but do not reach her. Janis calls us back on 6-18. We return her call and leave a voicemail. Janis calls us back on 6-24. We return her call, but her voicemail is turned off. We do not hear from Janis again.")


    10.times do |i|
      volunteer_user = User.create!(
                        name: "volunteer", 
                        email: "test_v#{i}@example.com",
                        primary_phone: "555-6#{i}5-0013", 
                        region: regions.first,
                        region_id: regions.first.id,
                        password: password, 
                        password_confirmation: password,
                        role: :volunteer,
                        pronouns: "she/they"
      )
      volunteer_person = volunteer_user.create_new_person
      volunteer = volunteer_person.create_new_volunteer
                        
      # Create associated objects
      case i
      when 1
        PaperTrail.request(whodunnit: volunteer_user.id) do
          volunteer_user.update!(name: "Other Contact info - one")
          volunteer_person.update!(
            emergency_contact: "Jane Doe",
            emergency_contact_phone: "234-456-6789", 
            emergency_contact_relationship: "Sister"
          )
        end
      when 2
        # appointment one week from today && clinic selected
        volunteer_user.update!(
          pronouns: "she/they"
        )
        volunteer_person.update!(
          zipcode: "20009"          
        )
      when 4
        PaperTrail.request(whodunnit: volunteer_user.id) do
          # With special circumstances
          volunteer_user.update!(
            name: "Special Circumstances - four"
          )
          volunteer_person.update!(
            special_circumstances: ["Prison", "Fetal anomaly"]
          )
        end
      end
      volunteer.save
    end
  end
end

# Log results
ActsAsTenant.without_tenant do
  puts "Seed completed! \n" \
       "Inserted #{Config.count} Config objects. \n" \
       "Inserted #{Event.count} Event objects. \n" \
       "Inserted #{Call.count} Call objects. \n" \
       "Inserted #{CallListEntry.count} CallListEntry objects. \n" \
       "Inserted #{Fulfillment.count} Fulfillment objects. \n" \
       "Inserted #{Note.count} Note objects. \n" \
       "Inserted #{Patient.count} Patient objects. \n" \
       "Inserted #{Procedure.count} Procedure objects. \n" \
       "Inserted #{ArchivedPatient.count} ArchivedPatient objects. \n" \
       "Inserted #{User.count} User objects. \n" \
       "Inserted #{Clinic.count} Clinic objects. \n" \
       "Inserted #{Org.count} Org objects. \n" \
       "Inserted #{Volunteer.count} Volunteer objects. \n" \
       "Inserted #{CareCoordinator.count} CareCoordinator objects. \n" \
       "User credentials are as follows: " \
       "EMAIL: #{User.where(role: :admin).first.email} PASSWORD: #{password}"
end
