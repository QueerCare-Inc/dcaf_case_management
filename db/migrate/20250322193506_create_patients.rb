class CreatePatients < ActiveRecord::Migration[7.2]
  def change
    create_table :patients do |t|
      t.references :org, foreign_key: true
      t.references :region, foreign_key: true
      t.references :person, foreign_key: true, null: false
      t.references :user, foreign_key: true

      t.string :patient_status

      t.string :voicemail_preference, default: 'not_specified'
      t.boolean :textable, default: false
      # t.string :region

      t.text :intake_date
      t.boolean :shared_flag

      t.boolean :multiday_appointment
      t.boolean :practical_support_waiver, comment: 'Optional practical support services waiver, for funds that use them'

      t.text :legal_name
      
      t.string :in_case_of_emergency, default: [], array: true

      t.string :insurance
      t.string :referred_by
      t.boolean :referred_to_clinic

      t.references :clinic, foreign_key: true
      t.references :last_edited_by, foreign_key: { to_table: :users }

      t.integer :current_procedure_id

      t.string :special_circumstances, array: true, default: []

      t.timestamps
    end

    add_index :patients, [:person_id, :region_id, :org_id], unique: true
    # add_index :patients, :emergency_contact_phone
    # add_index :patients, :emergency_contact
    # add_index :patients, :name
    add_index :patients, :shared_flag
    # add_index :patients, :identifier
  end
end
