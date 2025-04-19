# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_03_29_205219) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "archived_patients", force: :cascade do |t|
    t.string "identifier"
    t.string "age_range", default: "not_specified"
    t.boolean "has_alt_contact"
    t.string "voicemail_preference", default: "not_specified"
    t.string "language"
    t.date "intake_date"
    t.boolean "shared_flag"
    t.string "city"
    t.string "state"
    t.string "race_ethnicity"
    t.string "employment_status"
    t.string "insurance"
    t.string "income"
    t.integer "notes_count"
    t.boolean "has_special_circumstances"
    t.string "referred_by"
    t.boolean "referred_to_clinic"
    t.date "procedure_date"
    t.boolean "textable"
    t.boolean "multiday_appointment"
    t.boolean "practical_support_waiver"
    t.bigint "clinic_id"
    t.bigint "org_id"
    t.bigint "region_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "care_coordinator_id"
    t.index ["care_coordinator_id"], name: "index_archived_patients_on_care_coordinator_id"
    t.index ["clinic_id"], name: "index_archived_patients_on_clinic_id"
    t.index ["org_id"], name: "index_archived_patients_on_org_id"
    t.index ["region_id"], name: "index_archived_patients_on_region_id"
  end

  create_table "auth_factors", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "channel"
    t.boolean "enabled", default: false
    t.boolean "registration_complete", default: false
    t.string "external_id"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "user_id"], name: "index_auth_factors_on_name_and_user_id", unique: true
    t.index ["user_id"], name: "index_auth_factors_on_user_id"
  end

  create_table "call_list_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "person_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "org_id", null: false
    t.bigint "region_id", null: false
    t.string "region", null: false
    t.integer "order_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["org_id"], name: "index_call_list_entries_on_org_id"
    t.index ["patient_id", "person_id", "user_id", "org_id"], name: "idx_on_patient_id_person_id_user_id_org_id_d1db1fc4a2", unique: true
    t.index ["patient_id"], name: "index_call_list_entries_on_patient_id"
    t.index ["person_id"], name: "index_call_list_entries_on_person_id"
    t.index ["region_id"], name: "index_call_list_entries_on_region_id"
    t.index ["user_id"], name: "index_call_list_entries_on_user_id"
  end

  create_table "calls", force: :cascade do |t|
    t.integer "status", null: false
    t.string "can_call_type", null: false
    t.bigint "can_call_id", null: false
    t.bigint "org_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["can_call_type", "can_call_id"], name: "index_calls_on_can_call"
    t.index ["org_id"], name: "index_calls_on_org_id"
  end

  create_table "care_addresses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "region", null: false
    t.bigint "region_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "org_id", null: false
    t.string "street_address", null: false
    t.string "city", null: false
    t.string "state", null: false
    t.string "zip"
    t.string "phone", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.boolean "confirmed"
    t.decimal "coordinates", array: true
    t.boolean "qc_house"
    t.string "closest_cross_street"
    t.bigint "qc_housing_id"
    t.bigint "procedure_id", null: false
    t.string "can_care_address_type"
    t.bigint "can_care_address_id"
    t.index ["can_care_address_type", "can_care_address_id"], name: "index_care_addresses_on_can_care_address"
    t.index ["city"], name: "index_care_addresses_on_city"
    t.index ["confirmed"], name: "index_care_addresses_on_confirmed"
    t.index ["org_id"], name: "index_care_addresses_on_org_id"
    t.index ["patient_id"], name: "index_care_addresses_on_patient_id"
    t.index ["procedure_id"], name: "index_care_addresses_on_procedure_id"
    t.index ["qc_house"], name: "index_care_addresses_on_qc_house"
    t.index ["qc_housing_id"], name: "index_care_addresses_on_qc_housing_id"
    t.index ["region_id"], name: "index_care_addresses_on_region_id"
    t.index ["start_date", "coordinates", "org_id", "patient_id"], name: "idx_on_start_date_coordinates_org_id_patient_id_d85888402c", unique: true
    t.index ["start_date"], name: "index_care_addresses_on_start_date"
    t.index ["state"], name: "index_care_addresses_on_state"
  end

  create_table "care_coordinators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "person_id", null: false
    t.bigint "region_id"
    t.bigint "org_id"
    t.string "volunteer_types", default: [], array: true
    t.boolean "textable"
    t.index ["org_id"], name: "index_care_coordinators_on_org_id"
    t.index ["person_id", "region_id", "org_id"], name: "index_care_coordinators_on_person_id_and_region_id_and_org_id", unique: true
    t.index ["person_id"], name: "index_care_coordinators_on_person_id"
    t.index ["region_id"], name: "index_care_coordinators_on_region_id"
    t.index ["user_id"], name: "index_care_coordinators_on_user_id"
  end

  create_table "clinics", force: :cascade do |t|
    t.string "name", null: false
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "phone"
    t.string "fax"
    t.boolean "active", default: true, null: false
    t.boolean "accepts_medicaid"
    t.decimal "coordinates", array: true
    t.bigint "org_id"
    t.bigint "region_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "org_id"], name: "index_clinics_on_name_and_org_id", unique: true
    t.index ["org_id"], name: "index_clinics_on_org_id"
    t.index ["region_id"], name: "index_clinics_on_region_id"
  end

  create_table "configs", force: :cascade do |t|
    t.integer "config_key", null: false
    t.jsonb "config_value", default: {"options"=>[]}, null: false
    t.bigint "org_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["config_key", "org_id"], name: "index_configs_on_config_key_and_org_id", unique: true
    t.index ["org_id"], name: "index_configs_on_org_id"
  end

  create_table "events", force: :cascade do |t|
    t.integer "event_type"
    t.string "patient_name"
    t.string "patient_id"
    t.bigint "org_id"
    t.bigint "region_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_events_on_created_at"
    t.index ["org_id"], name: "index_events_on_org_id"
    t.index ["region_id"], name: "index_events_on_region_id"
  end

  create_table "fulfillments", force: :cascade do |t|
    t.boolean "fulfilled", default: false, null: false
    t.date "procedure_date"
    t.boolean "audited"
    t.string "can_fulfill_type", null: false
    t.bigint "can_fulfill_id", null: false
    t.bigint "org_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["audited"], name: "index_fulfillments_on_audited"
    t.index ["can_fulfill_type", "can_fulfill_id"], name: "index_fulfillments_on_can_fulfill"
    t.index ["fulfilled"], name: "index_fulfillments_on_fulfilled"
    t.index ["org_id"], name: "index_fulfillments_on_org_id"
  end

  create_table "notes", force: :cascade do |t|
    t.string "full_text", null: false
    t.bigint "patient_id"
    t.bigint "org_id"
    t.string "can_note_type"
    t.bigint "can_note_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["can_note_type", "can_note_id"], name: "index_notes_on_can_note"
    t.index ["org_id"], name: "index_notes_on_org_id"
    t.index ["patient_id"], name: "index_notes_on_patient_id"
  end

  create_table "old_passwords", force: :cascade do |t|
    t.string "encrypted_password", null: false
    t.string "password_archivable_type", null: false
    t.integer "password_archivable_id", null: false
    t.string "password_salt"
    t.datetime "created_at"
    t.index ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable"
  end

  create_table "orgs", force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.string "domain"
    t.string "full_name", comment: "Full name of the organization. e.g. DC Abortion Fund"
    t.string "site_domain", comment: "URL of the organization's public-facing website. e.g. www.dcabortionfund.org"
    t.string "phone", comment: "Contact number for the organization, usually the hotline"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "patients", force: :cascade do |t|
    t.bigint "org_id"
    t.bigint "region_id"
    t.bigint "person_id", null: false
    t.bigint "user_id"
    t.string "care_coordinator"
    t.string "voicemail_preference", default: "not_specified"
    t.date "intake_date"
    t.boolean "shared_flag"
    t.boolean "multiday_appointment"
    t.boolean "practical_support_waiver", comment: "Optional practical support services waiver, for funds that use them"
    t.string "legal_name"
    t.string "emergency_contact_options", default: [], array: true
    t.string "in_case_of_emergency", default: [], array: true
    t.string "insurance"
    t.string "referred_by"
    t.boolean "referred_to_clinic"
    t.bigint "clinic_id"
    t.bigint "last_edited_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "care_coordinator_id"
    t.string "can_patient_type"
    t.bigint "can_patient_id"
    t.index ["can_patient_type", "can_patient_id"], name: "index_patients_on_can_patient"
    t.index ["care_coordinator_id"], name: "index_patients_on_care_coordinator_id"
    t.index ["clinic_id"], name: "index_patients_on_clinic_id"
    t.index ["last_edited_by_id"], name: "index_patients_on_last_edited_by_id"
    t.index ["org_id"], name: "index_patients_on_org_id"
    t.index ["person_id", "region_id", "org_id"], name: "index_patients_on_person_id_and_region_id_and_org_id", unique: true
    t.index ["person_id"], name: "index_patients_on_person_id"
    t.index ["region_id"], name: "index_patients_on_region_id"
    t.index ["shared_flag"], name: "index_patients_on_shared_flag"
    t.index ["user_id"], name: "index_patients_on_user_id"
  end

  create_table "people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "region_id"
    t.bigint "org_id"
    t.string "identifier"
    t.string "emergency_contact"
    t.string "emergency_contact_phone"
    t.string "emergency_contact_relationship"
    t.string "language"
    t.integer "age"
    t.string "city"
    t.string "state"
    t.string "zipcode"
    t.string "race_ethnicity"
    t.string "employment_status"
    t.integer "household_size_children"
    t.integer "household_size_adults"
    t.string "income"
    t.string "status"
    t.string "special_circumstances", default: [], array: true
    t.boolean "textable"
    t.index ["identifier"], name: "index_people_on_identifier"
    t.index ["org_id"], name: "index_people_on_org_id"
    t.index ["region_id"], name: "index_people_on_region_id"
    t.index ["user_id", "region_id", "org_id"], name: "index_people_on_user_id_and_region_id_and_org_id", unique: true
    t.index ["user_id"], name: "index_people_on_user_id"
  end

  create_table "procedures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "region", null: false
    t.bigint "region_id", null: false
    t.bigint "person_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "org_id", null: false
    t.date "procedure_date", null: false
    t.string "type", null: false
    t.string "services", default: [], array: true
    t.date "service_start"
    t.date "intensive_service_end"
    t.date "service_end"
    t.string "status"
    t.string "can_procedure_type"
    t.bigint "can_procedure_id"
    t.index ["can_procedure_type", "can_procedure_id"], name: "index_procedures_on_can_procedure"
    t.index ["org_id"], name: "index_procedures_on_org_id"
    t.index ["patient_id", "procedure_date"], name: "index_procedures_on_patient_id_and_procedure_date", unique: true
    t.index ["patient_id"], name: "index_procedures_on_patient_id"
    t.index ["person_id"], name: "index_procedures_on_person_id"
    t.index ["region_id"], name: "index_procedures_on_region_id"
    t.index ["service_start"], name: "index_procedures_on_service_start"
    t.index ["services"], name: "index_procedures_on_services"
    t.index ["status"], name: "index_procedures_on_status"
    t.index ["type"], name: "index_procedures_on_type"
  end

  create_table "qc_housings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "region", null: false
    t.bigint "region_id", null: false
    t.bigint "volunteer_id", null: false
    t.bigint "org_id", null: false
    t.string "street_address", null: false
    t.string "city", null: false
    t.string "state", null: false
    t.string "zip"
    t.string "closest_cross_street"
    t.string "phone", null: false
    t.decimal "coordinates", array: true
    t.string "accessability"
    t.string "availabilities", default: [], array: true
    t.index ["availabilities"], name: "index_qc_housings_on_availabilities"
    t.index ["city"], name: "index_qc_housings_on_city"
    t.index ["coordinates", "org_id"], name: "index_qc_housings_on_coordinates_and_org_id", unique: true
    t.index ["org_id"], name: "index_qc_housings_on_org_id"
    t.index ["region_id"], name: "index_qc_housings_on_region_id"
    t.index ["state"], name: "index_qc_housings_on_state"
    t.index ["volunteer_id"], name: "index_qc_housings_on_volunteer_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "org_id", null: false
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "org_id"], name: "index_regions_on_name_and_org_id", unique: true
    t.index ["org_id"], name: "index_regions_on_org_id"
  end

  create_table "reimbursements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "region", null: false
    t.bigint "region_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "org_id", null: false
    t.date "date", null: false
    t.string "type", null: false
    t.string "amount", null: false
    t.string "status"
    t.string "can_reimburse_type"
    t.bigint "can_reimburse_id"
    t.index ["can_reimburse_type", "can_reimburse_id"], name: "index_reimbursements_on_can_reimburse"
    t.index ["date"], name: "index_reimbursements_on_date"
    t.index ["org_id"], name: "index_reimbursements_on_org_id"
    t.index ["patient_id"], name: "index_reimbursements_on_patient_id"
    t.index ["region_id"], name: "index_reimbursements_on_region_id"
    t.index ["status"], name: "index_reimbursements_on_status"
    t.index ["type"], name: "index_reimbursements_on_type"
  end

  create_table "resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "regions", default: [], array: true
    t.string "website_link"
    t.string "phone"
    t.string "email"
    t.string "contact_person"
    t.string "services_provided"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "shifts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "region", null: false
    t.bigint "region_id", null: false
    t.bigint "procedure_id", null: false
    t.bigint "patient_id", null: false
    t.bigint "care_address_id", null: false
    t.bigint "org_id", null: false
    t.string "type", null: false
    t.string "services", default: [], array: true
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "can_shift_type"
    t.bigint "can_shift_id"
    t.index ["can_shift_type", "can_shift_id"], name: "index_shifts_on_can_shift"
    t.index ["care_address_id", "org_id"], name: "index_shifts_on_care_address_id_and_org_id", unique: true
    t.index ["care_address_id"], name: "index_shifts_on_care_address_id"
    t.index ["org_id"], name: "index_shifts_on_org_id"
    t.index ["patient_id"], name: "index_shifts_on_patient_id"
    t.index ["procedure_id"], name: "index_shifts_on_procedure_id"
    t.index ["region_id"], name: "index_shifts_on_region_id"
    t.index ["services"], name: "index_shifts_on_services"
    t.index ["start_time"], name: "index_shifts_on_start_time"
    t.index ["type"], name: "index_shifts_on_type"
  end

  create_table "shifts_volunteers", force: :cascade do |t|
    t.bigint "shift_id"
    t.bigint "clinic_id"
    t.index ["clinic_id"], name: "index_shifts_volunteers_on_clinic_id"
    t.index ["shift_id"], name: "index_shifts_volunteers_on_shift_id"
  end

  create_table "surgeons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "region", null: false
    t.bigint "region_id", null: false
    t.bigint "org_id", null: false
    t.string "name", null: false
    t.string "email"
    t.string "phone", null: false
    t.string "procedure_types", default: [], array: true
    t.string "insurances", default: [], array: true
    t.boolean "active", default: true, null: false
    t.index ["active"], name: "index_surgeons_on_active"
    t.index ["insurances"], name: "index_surgeons_on_insurances"
    t.index ["name", "org_id"], name: "index_surgeons_on_name_and_org_id", unique: true
    t.index ["org_id"], name: "index_surgeons_on_org_id"
    t.index ["procedure_types"], name: "index_surgeons_on_procedure_types"
    t.index ["region_id"], name: "index_surgeons_on_region_id"
  end

  create_table "surgeons_clinics", force: :cascade do |t|
    t.bigint "surgeon_id"
    t.bigint "clinic_id"
    t.index ["clinic_id"], name: "index_surgeons_clinics_on_clinic_id"
    t.index ["surgeon_id"], name: "index_surgeons_clinics_on_surgeon_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "region"
    t.integer "role", default: 0, null: false
    t.boolean "disabled_by_org", default: false
    t.bigint "org_id"
    t.string "primary_phone", default: "-5555", null: false
    t.string "pronouns"
    t.bigint "region_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.string "unique_session_id"
    t.string "session_validity_token"
    t.index ["email", "org_id"], name: "index_users_on_email_and_org_id", unique: true
    t.index ["org_id"], name: "index_users_on_org_id"
    t.index ["primary_phone", "org_id"], name: "index_users_on_primary_phone_and_org_id", unique: true
    t.index ["region_id"], name: "index_users_on_region_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type"
    t.string "{:null=>false}"
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.json "object"
    t.json "object_changes"
    t.bigint "org_id"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["org_id"], name: "index_versions_on_org_id"
  end

  create_table "volunteers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "person_id", null: false
    t.bigint "region_id"
    t.bigint "org_id"
    t.string "shifts", default: [], array: true
    t.string "volunteer_types", default: [], array: true
    t.bigint "qc_housing_id"
    t.index ["org_id"], name: "index_volunteers_on_org_id"
    t.index ["person_id", "region_id", "org_id"], name: "index_volunteers_on_person_id_and_region_id_and_org_id", unique: true
    t.index ["person_id"], name: "index_volunteers_on_person_id"
    t.index ["qc_housing_id"], name: "index_volunteers_on_qc_housing_id"
    t.index ["region_id"], name: "index_volunteers_on_region_id"
    t.index ["user_id"], name: "index_volunteers_on_user_id"
  end

  add_foreign_key "archived_patients", "care_coordinators"
  add_foreign_key "archived_patients", "clinics"
  add_foreign_key "archived_patients", "orgs"
  add_foreign_key "archived_patients", "regions"
  add_foreign_key "auth_factors", "users"
  add_foreign_key "call_list_entries", "orgs"
  add_foreign_key "call_list_entries", "patients"
  add_foreign_key "call_list_entries", "people"
  add_foreign_key "call_list_entries", "regions"
  add_foreign_key "call_list_entries", "users"
  add_foreign_key "calls", "orgs"
  add_foreign_key "care_addresses", "orgs"
  add_foreign_key "care_addresses", "patients"
  add_foreign_key "care_addresses", "procedures"
  add_foreign_key "care_addresses", "qc_housings"
  add_foreign_key "care_addresses", "regions"
  add_foreign_key "care_coordinators", "orgs"
  add_foreign_key "care_coordinators", "people"
  add_foreign_key "care_coordinators", "regions"
  add_foreign_key "care_coordinators", "users"
  add_foreign_key "clinics", "orgs"
  add_foreign_key "clinics", "regions"
  add_foreign_key "configs", "orgs"
  add_foreign_key "events", "orgs"
  add_foreign_key "events", "regions"
  add_foreign_key "fulfillments", "orgs"
  add_foreign_key "notes", "orgs"
  add_foreign_key "patients", "care_coordinators"
  add_foreign_key "patients", "clinics"
  add_foreign_key "patients", "orgs"
  add_foreign_key "patients", "people"
  add_foreign_key "patients", "regions"
  add_foreign_key "patients", "users"
  add_foreign_key "patients", "users", column: "last_edited_by_id"
  add_foreign_key "people", "orgs"
  add_foreign_key "people", "regions"
  add_foreign_key "people", "users"
  add_foreign_key "procedures", "orgs"
  add_foreign_key "procedures", "patients"
  add_foreign_key "procedures", "people"
  add_foreign_key "procedures", "regions"
  add_foreign_key "qc_housings", "orgs"
  add_foreign_key "qc_housings", "regions"
  add_foreign_key "qc_housings", "volunteers"
  add_foreign_key "regions", "orgs"
  add_foreign_key "reimbursements", "orgs"
  add_foreign_key "reimbursements", "patients"
  add_foreign_key "reimbursements", "regions"
  add_foreign_key "shifts", "care_addresses"
  add_foreign_key "shifts", "orgs"
  add_foreign_key "shifts", "patients"
  add_foreign_key "shifts", "procedures"
  add_foreign_key "shifts", "regions"
  add_foreign_key "surgeons", "orgs"
  add_foreign_key "surgeons", "regions"
  add_foreign_key "users", "orgs"
  add_foreign_key "users", "regions"
  add_foreign_key "versions", "orgs"
  add_foreign_key "volunteers", "orgs"
  add_foreign_key "volunteers", "people"
  add_foreign_key "volunteers", "qc_housings"
  add_foreign_key "volunteers", "regions"
  add_foreign_key "volunteers", "users"
end
