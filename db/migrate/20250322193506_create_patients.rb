class CreatePatients < ActiveRecord::Migration[7.2]
  def change
    create_table :patients do |t|
      t.references :org, foreign_key: true
      t.references :region, foreign_key: true
      t.references :person, foreign_key: true, null: false
      t.references :user, foreign_key: true

      # t.belongs_to :user #redundant??
      # t.belongs_to :person #redundant??

      t.string :care_coordinator

      t.string :voicemail_preference, default: 'not_specified'
      # t.string :region

      t.date :intake_date
      t.boolean :shared_flag

      t.boolean :multiday_appointment
      t.boolean :practical_support_waiver, comment: 'Optional practical support services waiver, for funds that use them'

      t.string :legal_name
      t.string :emergency_contact_options, array: true, default: []
      t.string :in_case_of_emergency, default: [], array: true

      t.string :insurance
      t.string :referred_by
      t.boolean :referred_to_clinic

      t.references :clinic, foreign_key: true
      t.references :last_edited_by, foreign_key: { to_table: :users }

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
