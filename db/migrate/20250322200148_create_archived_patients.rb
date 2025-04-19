class CreateArchivedPatients < ActiveRecord::Migration[7.2]
  def change
    create_table :archived_patients do |t|
      t.string :identifier

      # Generated from initial patient info
      t.string :age_range, default: 'not_specified'
      t.boolean :has_alt_contact

      # Pulled directly from initial patient
      t.string :voicemail_preference, default: 'not_specified'
      # t.string :region, null: false
      t.string :language
      t.date :intake_date
      t.boolean :shared_flag
      t.string :city
      t.string :state
      t.string :race_ethnicity
      t.string :employment_status
      t.string :insurance
      t.string :income
      t.integer :notes_count
      t.boolean :has_special_circumstances
      t.string :referred_by
      t.boolean :referred_to_clinic
      t.date :procedure_date
      t.boolean :textable
      t.boolean :multiday_appointment
      t.boolean :practical_support_waiver

      t.references :clinic, foreign_key: true
      t.references :org, foreign_key: true
      t.references :region, foreign_key: true

      t.timestamps
    end

    # add_index :archived_patients, :region
  end
end
