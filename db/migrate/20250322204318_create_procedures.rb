class CreateProcedures < ActiveRecord::Migration[7.2]
  def change
    create_table :procedures do |t|
      t.timestamps

      # belongs to
      t.string :region
      t.references :region, foreign_key: true, null: false
      t.references :person, foreign_key: true, null: false
      t.references :patient, foreign_key: true, null: false
      t.references :org, foreign_key: true, null: false
      t.references :clinic, foreign_key: true
      t.references :surgeon, foreign_key: true

      # attributes
      t.text :procedure_date, null: false
      t.integer :procedure_type, null: false, default: 0 # not_specified
      t.string :services, array: true, default: []
      t.text :service_start
      t.text :intensive_service_end
      t.text :service_end
      t.integer :care_status, null: false, default: 0 # new_care_request
      t.text :intake_date

      # has many
      # care addresses, shifts, reimbursements
    end
    add_index :procedures, [:patient_id, :procedure_date], unique: true
    add_index :procedures, [:patient_id, :procedure_date, :surgeon_id, :clinic_id], unique: true
    add_index :procedures, :procedure_type
    add_index :procedures, :services
    add_index :procedures, :service_start
    add_index :procedures, :care_status
  end
end
