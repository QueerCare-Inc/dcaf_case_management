# Set up fixtures and database seeds to simulate a production environment.
raise "No running seeds in prod" unless [nil, "Sandbox"].include? ENV["DARIA_FUND"]

Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '[5]{10}' # this will add number 1-555-555-5555 to be valid

# Clear out existing DB
ActsAsTenant.without_tenant do
  Config.destroy_all
  Event.destroy_all
  CareRequestEntry.destroy_all
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
  ShiftEntry.destroy_all
  Surgeon.destroy_all
  Reimbursement.destroy_all
end

def generate_central_office_code(area_code)
  first_digit = rand(2..9).to_s
  second_digit = rand(0..9).to_s
  third_digit = rand(0..9).to_s
  
  return first_digit + second_digit + third_digit
end

def generate_random_us_phone_number
  us_area_codes = [
    '907',
    '205', '251', '256', '334', '938',
    '479', '501', '870',
    '480', '520', '602', '623', '928',
    '209', '213', '310', '323', '408', '415', '424', '442', '510', '530', '559', '562', '619', '626', '650', '661', '707', '714', '760', '805', '818', '831', '858', '909', '916', '925',
    '303', '719', '970',
    '203', '860',
    '202',
    '302',
    '239', '305', '321', '352', '386', '407', '561', '727', '754', '772', '786', '813', '850', '863', '904', '941', '954',
    '229', '404', '470', '478', '678', '706', '762', '770', '912',
    '808',
    '319', '515', '563', '641', '712',
    '208',
    '217', '224', '309', '312', '331', '618', '630', '708', '773', '815', '847',
    '219', '260', '317', '574', '765', '812',
    '316', '620', '785', '913',
    '270', '502', '606', '859',
    '225', '318', '337', '504', '985',
    '413', '508', '617', '774', '781', '857', '978',
    '301', '410',
    '207',
    '231', '248', '269', '313', '517', '586', '616', '734', '810', '906', '989',
    '218', '320', '507', '612', '651', '763', '952',
    '314', '417', '573', '636', '660', '816',
    '228', '601', '662',
    '406',
    '252', '336', '704', '828', '910', '919',
    '701',
    '308', '402',
    '603',
    '201', '609', '732', '848', '856', '862', '908', '973',
    '505', '575',
    '702', '775',
    '212', '315', '347', '516', '518', '585', '607', '631', '646', '716', '718', '845', '914',
    '216', '234', '330', '419', '440', '513', '567', '614', '740', '937',
    '405', '580', '918',
    '503', '541',
    '215', '267', '412', '484', '570', '610', '717', '724', '814',
    '401',
    '803', '843', '864',
    '605',
    '423', '615', '731', '865', '901', '931',
    '210', '214', '254', '281', '325', '361', '409', '430', '432', '512', '682', '713', '737', '806', '817', '830', '832', '903', '915', '936', '940', '956', '972', '979',
    '435', '801', 
    '276', '434', '540', '571', '703', '757', '804',
    '802',
    '206', '253', '360', '425', '509',
    '262', '414', '608', '715', '920',
    '304',
    '307'
  ]

  # Generate a random 10-digit number
  random_number = rand(4**4).to_s.rjust(4, '0')

  us_area_code = us_area_codes.sample
  
  central_office_code = generate_central_office_code(us_area_code)

  # Parse the number with Phonelib
  phone = Phonelib.parse(us_area_code + central_office_code + random_number, 'US')
  # Check if the number is valid
  if phone.valid?
    # print "Generated phone number: #{phone.e164}\n"
    phone.e164
  else
    generate_random_us_phone_number
  end
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
        phone_number: generate_random_us_phone_number #"202-452-7464"
)

org2 = Org.create!(
        name: "CatFund",
        domain: "petfinder.com",
        subdomain: "catbox",
        full_name: "Cat Fund",
        site_domain: "www.petfinder.com",
        phone_number: generate_random_us_phone_number #"(281) 330-8004"
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
                  primary_phone: generate_random_us_phone_number, #"456-123-1231", 
                  region: regions.first,
                  region_id: regions.first.id,
                  password: password, 
                  password_confirmation: password,
                  role: :admin
    )

    cc_user1 = User.create!(
                  name: "testuser two", 
                  email: "test2@example.com",
                  primary_phone: generate_random_us_phone_number, #"456-123-1232", 
                  region: regions.first,
                  region_id: regions.first.id,
                  password: password, 
                  password_confirmation: password,
                  role: :care_coordinator
    )
    cc_person1 = cc_user1.create_new_person
    care_coordinator1 = cc_person1.create_new_care_coordinator
    care_coordinator1.update!(
      volunteer_types: ["remote", "transportation"]
    )

    cc_user2 = User.create!(
                  name: "testuser three", 
                  email: "test3@example.com",
                  primary_phone: generate_random_us_phone_number, #"456-123-1233", 
                  region: regions.second,
                  region_id: regions.second.id,
                  password: password, 
                  password_confirmation: password,
                  role: :care_coordinator
    )
    cc_person2 = cc_user2.create_new_person
    care_coordinator2 = cc_person2.create_new_care_coordinator
    care_coordinator2.update!(
      volunteer_types: ["transportation", "in-person"]
    )

    # finance_user = User.create! name: "testuser five",
    #                       email: "test5@example.com",
    #                       primary_phone: generate_random_us_phone_number, #"456-123-1235", 
    #                       region: regions.second,
    #                       password: password, 
    #                       password_confirmation: password,
    #                       role: :finance_admin

    cc_admin_user = User.create! name: "testuser six", 
                          email: "test6@example.com",
                          primary_phone: generate_random_us_phone_number, #"456-123-1236", 
                          region: regions.first,
                          password: password, 
                          password_confirmation: password,
                          role: :coord_admin

     
    # Default to cc_user1 as the actor
    PaperTrail.request.whodunnit = cc_user1.id

    # Create a few clinics
    clinic1 = Clinic.create!(
      name: "Sample Clinic 1 - DC", 
      street_address: "1600 Pennsylvania Ave",
      city: "Washington", state: "DC", zip: "20500",
      # phone_number: generate_random_us_phone_number,
      region_id: regions.first.id
    )
    clinic2 = Clinic.create!(
      name: "Sample Clinic 2 - VA", 
      street_address: "1400 Defense",
      city: "Arlington", state: "VA", zip: "20301",
      # phone_number: generate_random_us_phone_number,
      region_id: regions.second.id
    )
    clinic3 = Clinic.create!(
      name: "Sample Clinic with NAF", 
      street_address: "815 V Street NW",
      city: "Washington", state: "DC", zip: "20001",
      # phone_number: generate_random_us_phone_number,
      region_id: regions.first.id
    )
    clinic4 = Clinic.create!(
      name: "Sample Clinic without NAF", 
      street_address: "1811 14th Street NW",
      city: "Washington", state: "DC", zip: "20009", accepts_medicaid: true,
      # phone_number: generate_random_us_phone_number,
      region_id: regions.second.id
    )
    
    # Create a few surgeons
    surgeon1 = Surgeon.create!(
      region: regions.first,
      name: "Dr. One", 
      phone_number: generate_random_us_phone_number, #"968-574-3625",
      procedure_type_list: Procedure.procedure_types.slice(:breast_augmentation, :mastectomy).values,
      region_id: regions.first.id
    )

    surgeon2 = Surgeon.create!(
      region: regions.first,
      name: "Dr. Two", 
      phone_number: generate_random_us_phone_number, #"142-536-9685",
      procedure_type_list: Procedure.procedure_types.slice(:facial_feminization, :facial_masculinization).values,
      region_id: regions.first.id
    )

    surgeon3 = Surgeon.create!(
      region: regions.second,
      name: "Dr. Three", 
      phone_number: generate_random_us_phone_number, #"635-241-7485",
      procedure_type_list: Procedure.procedure_types.slice(:vaginoplasty).values,
      region_id: regions.second.id
    )

    surgeon4 = Surgeon.create!(
      region: regions.second,
      name: "Dr. Four", 
      phone_number: generate_random_us_phone_number, #"415-263-8574",
      procedure_type_list: Procedure.procedure_types.slice(:metoidioplasty, :phalloplasty).values,
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
                  primary_phone: generate_random_us_phone_number, #"123-123-123#{i}", 
                  pronouns: "he/she/they",
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
      procedure = patient.create_new_procedure

      # procedure_type_value = Procedure.procedure_types[:other]
      # care_status_value = Procedure.care_statuses[:new_care_request]

      # debugger 
      # # puts "Procedure type value: #{procedure_type_value}" # Debugging
      # # puts "Care status value: #{care_status_value}"       # Debugging

      # procedure = Procedure.new(
      #   org_id: org.id,
      #   region_id: regions.first.id,
      #   person_id: cr_person.id,
      #   patient_id: patient.id,
      #   procedure_date: Date.today + 1.month,
      #   procedure_type: procedure_type_value,
      #   care_status: care_status_value
      # )

      procedure.save!
      # procedure = patient.get_current_procedure
      
      # Create associated objects
      if i.even? && i < 6
        PaperTrail.request(whodunnit: admin_user.id) do
          # patient.update!(
          #   care_coordinator_id: care_coordinator1.id
          # )
          
          care_request_entry = CareRequestEntry.where(procedure_id: procedure.id).first
          care_request_entry.update!(
            care_coordinator_id: care_coordinator1.id
          )
          
          procedure.update!(
            care_status: Procedure.care_statuses[:coordinator_assigned]
          )
        end
      elsif i < 6
        PaperTrail.request(whodunnit: admin_user.id) do
          # patient.update!(
          #   care_coordinator_id: care_coordinator2.id
          # )
          
          care_request_entry = CareRequestEntry.where(procedure_id: procedure.id).first
          care_request_entry.update!(
            care_coordinator_id: care_coordinator2.id
          )
          procedure.update!(
            care_status: Procedure.care_statuses[:coordinator_assigned]
          )
        end
      end

      case i
      
      when 0
        PaperTrail.request(whodunnit: cc_user1.id) do
          cr_person.update!(
            emergency_contact: "Jane Doe",
            emergency_contact_phone: generate_random_us_phone_number, #"234-456-6789", 
            emergency_contact_relationship: "Sister",
            language: 'English',
            age: 32,
            city: 'San Francisco',
            state: 'CA'
          )
          patient.update!(
            intake_date: Date.today + i.day,
          )

          procedure.update!(
            procedure_date: Date.today + (i+7).days,
            service_start: Date.today + (i+10).days,
            intensive_service_end: Date.today + (i+24).days,
            service_end: Date.today + (i+40).days,
            procedure_type: Procedure.procedure_types[:breast_augmentation],
            services: ["Transportation", "Chores"],
            care_status: Procedure.care_statuses[:intake_complete],
            surgeon_id: surgeon1.id,
            clinic_id: clinic1.id
          )

          # add a care address
          care_address = procedure.create_new_care_address

          care_address.update!(
            street_address: "1600 Pennsylvania Ave NW",
            city: "Washington",
            state: "DC",
            start_date: Date.today + (i+10).days,
            end_date: Date.today + (i+15).days,
            # coordinates: { lat: 38.89511, lng: -77.03637 }, # White House coordinates
            closest_cross_street: "Pennsylvania Ave NW & 15th St NW",
            confirmed: false
          )
          care_address.update_coordinates

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "1 First Street",
            city: "Washington",
            state: "DC",
            start_date: Date.today + (i+16).days,
            end_date: Date.today + (i+20).days,
            # coordinates: { lat: 38.890556, lng: -77.004444 }, # Supreme Court
            closest_cross_street: "First St NE & Maryland Ave NE",
            confirmed: false
          )
          care_address.update_coordinates

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "101 Independence Ave SE",
            city: "Washington",
            state: "DC",
            start_date: Date.today + (i+21).days,
            end_date: Date.today + (i+30).days,
            # coordinates: { lat: 38.888611, lng: -77.004722 }, # Library of Congress
            closest_cross_street: "Independence Ave SE & 1st St SE",
            confirmed: false
          )
          care_address.update_coordinates

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "1401 Pennsylvania Ave NW",
            city: "Washington",
            state: "DC",
            start_date: Date.today + (i+31).days,
            end_date: Date.today + (i+40).days,
            # coordinates: { lat: 38.896667, lng: -77.03222 }, # Willard's Hotel
            closest_cross_street: "Pennsylvania Ave NW & 14th St NW",
            confirmed: false
          )
          care_address.update_coordinates
          
          procedure.generate_shifts
        end  
      when 1
        PaperTrail.request(whodunnit: cc_user2.id) do
          cr_person.update!(
            emergency_contact: "June Doe",
            emergency_contact_phone: generate_random_us_phone_number, #"134-456-6789", 
            emergency_contact_relationship: "Spouse",
            language: 'English',
            age: 35,
            city: 'San Francisco',
            state: 'CA'
          )
          patient.update!(
            intake_date: Date.today + i.day,
          )
          procedure.update!(
            procedure_date: Date.today + (i+7).days,
            service_start: Date.today + (i+10).days,
            intensive_service_end: Date.today + (i+24).days,
            service_end: Date.today + (i+40).days,
            care_status: Procedure.care_statuses[:intake_complete],
            surgeon_id: surgeon2.id,
            clinic_id: clinic3.id
          )

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "600 Montgomery St",
            city: "San Francisco",
            state: "CA",
            start_date: Date.today + (i+10).days,
            end_date: Date.today + (i+20).days,
            # coordinates: { lat: 37.7852, lng: -122.4028 }, # Transamerica Pyramid
            closest_cross_street: "Montgomery St & Clay St",
            confirmed: false
          )
          care_address.update_coordinates

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "950 Mason St",
            city: "San Francisco",
            state: "CA",
            start_date: Date.today + (i+21).days,
            end_date: Date.today + (i+30).days,
            # coordinates: { lat: 37.7924, lng: -122.4102 }, # Fairmont Hotel
            closest_cross_street: "Mason St & California St",
            confirmed: false
          )
          care_address.update_coordinates

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "1635 Woods Dr",
            city: "Los Angeles",
            state: "CA",
            start_date: Date.today + (i+31).days,
            end_date: Date.today + (i+40).days,
            # coordinates: { lat: 37.100437, lng: -118.370152 }, # Stahl House
            closest_cross_street: "Woods Dr & Mulholland Dr",
            confirmed: false
          )
          care_address.update_coordinates

          procedure.generate_shifts
        end
      when 2
        PaperTrail.request(whodunnit: cc_user2.id) do
          cr_person.update!(
            emergency_contact: "Henry Doe",
            emergency_contact_phone: generate_random_us_phone_number, #"904-456-6789", 
            emergency_contact_relationship: "Sibling",
            language: 'English',
            age: 26,
            city: 'San Francisco',
            state: 'CA'
          )
          patient.update!(
            intake_date: Date.today + i.day,
          )
          procedure.update!(
            procedure_date: Date.today + (i+7).days,
            service_start: Date.today + (i+10).days,
            intensive_service_end: Date.today + (i+24).days,
            service_end: Date.today + (i+40).days,
            care_status: Procedure.care_statuses[:intake_complete],
            surgeon_id: surgeon3.id,
            clinic_id: clinic2.id
          )

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "5 Embarcadero Center",
            city: "San Francisco",
            state: "CA",
            start_date: Date.today + (i+10).days,
            end_date: Date.today + (i+20).days,
            # coordinates: { lat: 37.79432, lng: -122.39584 }, # Hyatt Regency
            closest_cross_street: "Embarcadero Center & Market St",
            confirmed: false
          )
          care_address.update_coordinates

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "4 Westmoreland Pl",
            city: "Pasadena",
            state: "CA",
            start_date: Date.today + (i+21).days,
            end_date: Date.today + (i+30).days,
            # coordinates: { lat: 34.151561, lng: -118.1608 }, # Gamble House
            closest_cross_street: "Westmoreland Pl & S Orange Grove Blvd",
            confirmed: false
          )
          care_address.update_coordinates

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "1500 Orange Ave",
            city: "Coronado",
            state: "CA",
            start_date: Date.today + (i+31).days,
            end_date: Date.today + (i+40).days,
            # coordinates: { lat: 32.6809, lng: -117.1784 }, # Hotel del Coronado
            closest_cross_street: "Orange Ave & 1st St",
            confirmed: false
          )
          care_address.update_coordinates
          procedure.generate_shifts
        end
        PaperTrail.request(whodunnit: admin_user.id) do
          procedure.update!(
            care_status: Procedure.care_statuses[:accepted_care_request]
          )
        end
      when 3
        PaperTrail.request(whodunnit: cc_user1.id) do
          cr_person.update!(
            emergency_contact: "Jason Doe",
            emergency_contact_phone: generate_random_us_phone_number, #"111-456-6789", 
            emergency_contact_relationship: "Spouse",
            language: 'English',
            age: 29,
            city: 'San Francisco',
            state: 'CA'
          )
          patient.update!(
            intake_date: (i+10).days.ago,
          )
          procedure.update!(
            procedure_date: (i+7).days.ago,
            service_start: (i+6).days.ago,
            intensive_service_end: Date.today + (i+8).days,
            service_end: Date.today + (i+20).days,
            care_status: Procedure.care_statuses[:intake_complete],
            surgeon_id: surgeon4.id,
            clinic_id: clinic4.id
          )

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "1491 Mill Run Rd",
            city: "Mill Run",
            state: "PA",
            start_date: Date.today + (i+10).days,
            end_date: Date.today + (i+40).days,
            # coordinates: { lat: 39.906111, lng: -79.468056 }, # Fallingwater
            closest_cross_street: "Mill Run Rd & PA-381",
            confirmed: false
          )
          care_address.update_coordinates
          procedure.generate_shifts
        end
        PaperTrail.request(whodunnit: admin_user.id) do
          procedure.update!(
            care_status: Procedure.care_statuses[:accepted_care_request]
          )
        end
        procedure.update!(
          care_status: Procedure.care_statuses[:procedure_confirmed]
        )
      when 4
        PaperTrail.request(whodunnit: cc_user1.id) do
          cr_person.update!(
            emergency_contact: "Jimmy Doe",
            emergency_contact_phone: generate_random_us_phone_number, #"222-456-6789", 
            emergency_contact_relationship: "Son",
            language: 'English',
            age: 45,
            city: 'San Francisco',
            state: 'CA'
          )
          patient.update!(
            intake_date: (i+10).days.ago,
          )
          procedure.update!(
            procedure_date: (i+7).days.ago,
            service_start: (i+6).days.ago,
            intensive_service_end: Date.today + (i+8).days,
            service_end: Date.today + (i+20).days,
            care_status: Procedure.care_statuses[:intake_complete],
            surgeon_id: surgeon4.id,
            clinic_id: clinic4.id
          )

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "44 West 44th St",
            city: "New York",
            state: "NY",
            start_date: Date.today + (i+10).days,
            end_date: Date.today + (i+20).days,
            # coordinates: { lat: 40.755556, lng: -73.982222 }, # Royalton Hotel
            closest_cross_street: "West 44th St & 6th Ave",
            confirmed: false
          )
          care_address.update_coordinates

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "760 United Nations Plaza",
            city: "New York",
            state: "NY",
            start_date: Date.today + (i+21).days,
            end_date: Date.today + (i+30).days,
            # coordinates: { lat: 40.749444, lng: -73.968056 }, # UN Headquarters
            closest_cross_street: "1st Ave & E 44th St",
            confirmed: false
          )
          care_address.update_coordinates

          # add a care address
          care_address = procedure.create_new_care_address
          care_address.update!(
            street_address: "1 West 72nd St",
            city: "New York",
            state: "NY",
            start_date: Date.today + (i+31).days,
            end_date: Date.today + (i+40).days,
            # coordinates: { lat: 40.776667, lng: -73.976389 }, # The Dakota
            closest_cross_street: "West 72nd St & Central Park West",
            confirmed: false
          )
          care_address.update_coordinates
          procedure.generate_shifts
        end
        PaperTrail.request(whodunnit: admin_user.id) do
          procedure.update!(
            care_status: Procedure.care_statuses[:accepted_care_request]
          )
        end
        procedure.update!(
          care_status: Procedure.care_statuses[:under_care]
        )
      when 5
        PaperTrail.request(whodunnit: admin_user.id) do
          # With special circumstances
          cr_user.update!(name: "Special Circumstances - four")
          patient.update!(special_circumstances: ["Prison", "Fetal anomaly"])
          # # And a recent call on file
          # patient.calls.create!(status: :left_voicemail)
        end
      end

      # if i != 9
      #   5.times do
      #     patient.calls.create!(
      #       status: :left_voicemail,
      #       created_at: 3.days.ago
      #     )
      #   end
      # end

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
    #     primary_phone: generate_random_us_phone_number, #"321-0#{i}0-001#{rand(10)}",
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
    #     primary_phone: generate_random_us_phone_number, #"321-0#{patient_number}0-002#{rand(10)}",
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
    #     primary_phone: generate_random_us_phone_number, #"321-0#{patient_number}0-003#{rand(10)}",
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
    #     primary_phone: generate_random_us_phone_number, #"321-0#{patient_number}0-004#{rand(10)}",
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
                  primary_phone: generate_random_us_phone_number, #"321-0#{patient_number}0-005#{rand(10)}", 
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

      # # Call, but no answer. leave a VM.
      # patient.calls.create(status: :left_voicemail, created_at: 139.days.ago)

      # # Call, which updates patient info, maybe flags shared, make a note.
      # patient.calls.create(status: :reached_patient, created_at: 138.days.ago)

      patient.update!(
        # procedure_date: 130.days.ago,
        # clinic: Clinic.all.sample,
        special_circumstances: ["", "", "Homelessness", "", "", "Other medical issue", "", "", ""],
        referred_to_clinic: patient_number.odd?,
        updated_at: 139.days.ago # not sure if this even works?
      )
      cr_person.update!(
        age: 24,
        race_ethnicity: "Hispanic/Latino",
        city: "Washington",
        state: "DC",
        emergency_contact: "Susie Q.",
        emergency_contact_phone: generate_random_us_phone_number, #"555-0#{patient_number}0-0053",
        emergency_contact_relationship: "Mother",
        employment_status: "Student",
        income: "$10,000-14,999",
        household_size_adults: 3,
        household_size_children: 2,
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

      # # another call. get abortion information, create pledges, a note.
      # patient.calls.create!(status: :reached_patient, created_at: 136.days.ago)

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
                  primary_phone: generate_random_us_phone_number, #"867-9#{patient_number}0-004#{rand(10)}", 
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

      # # Call, but no answer. leave a VM.
      # patient.calls.create(status: :left_voicemail, created_at: 639.days.ago)

      # # Call, which updates patient info, maybe flags, make a note.
      # patient.calls.create(status: :reached_patient, created_at: 138.days.ago)

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
        referred_to_clinic: patient_number.odd?,
        special_circumstances: ["", "", "Homelessness", "", "", "Other medical issue", "", "", ""]
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
        emergency_contact_phone: generate_random_us_phone_number, #"555-6#{patient_number}0-0053",
        emergency_contact_relationship: "Mother",
        employment_status: "Student",
        income: "$10,000-14,999",
        household_size_adults: 3,
        household_size_children: 2        
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
                primary_phone: generate_random_us_phone_number, #"000-000-0001", 
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
    # regina.calls.create!(
    #   created_at: 30.days.ago,
    #   status: "reached_patient"
    # )
    # regina.update(
    #   # procedure_date: 18.days.ago,
    #   # clinic: Clinic.first
    # )

    # regina.calls.create!(
    #   created_at: 22.days.ago,
    #   status: "reached_patient"
    # )
    regina.fulfillment.update(
      fulfilled: true,
      # procedure_date: 18.days.ago
    )

    regina.notes.create!(full_text: "SCENARIO: Regina calls us at 6 weeks LMP on 3-12. We call her back and reach the patient. We explain the org's policies of only funding after 7 weeks LMP. Regina’s options are to either schedule her appointment a week from the day she calls or org her procedure on her own. We offer her references to clinics who will be able to see her and the number to other funders who may be able to help her. We emphasize although we cannot org her now financially, we can in the future and she should call us back if that is the case. She says she will make an appointment for two weeks out. Regina calls us back on 3-20. Her funding is completed. We send the pledge to the clinic on Regina's behalf. Regina goes to her appointment on 3-24 and has her abortion. The clinic mails us back the completed pledge form on 4-15. Org checks the pledge against our system, completes an entry in our ledger, notes the completed pledge on Regina's file in DARIA (which then anon’s her data eventually), writes a check to the clinic and mails the check it to the clinic.")

    cr_user = User.create!(
                name: "Janis", 
                email: "janis@example.com",
                primary_phone: generate_random_us_phone_number, #"000-000-0002", 
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
    
    # janis.calls.create!(
    #   created_at: 40.days.ago,
    #   status: "left_voicemail"
    # )
    # janis.calls.create!(
    #   created_at: 40.days.ago,
    #   status: "left_voicemail"
    # )
    # janis.calls.create!(
    #   created_at: 39.days.ago,
    #   status: "left_voicemail"
    # )
    # janis.calls.create!(
    #   created_at: 40.days.ago,
    #   status: "couldnt_reach_patient"
    # )
    janis.notes.create(full_text: "SCENARIO: Janis calls us on 6-17. We call her back and leave a voicemail. We try again at the end of the night, but do not reach her. Janis calls us back on 6-18. We return her call and leave a voicemail. Janis calls us back on 6-24. We return her call, but her voicemail is turned off. We do not hear from Janis again.")


    10.times do |i|
      volunteer_user = User.create!(
                        name: "volunteer", 
                        email: "test_v#{i}@example.com",
                        primary_phone: generate_random_us_phone_number, #"555-6#{i}5-0013", 
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
            emergency_contact_phone: generate_random_us_phone_number, #"234-456-6789", 
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
       "Inserted #{CareRequestEntry.count} CareRequestEntry objects. \n" \
       "Inserted #{Fulfillment.count} Fulfillment objects. \n" \
       "Inserted #{Note.count} Note objects. \n" \
       "Inserted #{Patient.count} Patient objects. \n" \
       "Inserted #{Procedure.count} Procedure objects. \n" \
       "Inserted #{Shift.count} Shift objects. \n" \
       "Inserted #{CareAddress.count} CareAddress objects. \n" \
       "Inserted #{ArchivedPatient.count} ArchivedPatient objects. \n" \
       "Inserted #{User.count} User objects. \n" \
       "Inserted #{Clinic.count} Clinic objects. \n" \
       "Inserted #{Org.count} Org objects. \n" \
       "Inserted #{Volunteer.count} Volunteer objects. \n" \
       "Inserted #{CareCoordinator.count} CareCoordinator objects. \n" \
       "User credentials are as follows: " \
       "EMAIL: #{User.where(role: :admin).first.email} PASSWORD: #{password}"
end
