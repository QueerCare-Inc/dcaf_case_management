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

      # t.belongs_to :patient #redundant??

      # attributes
      t.boolean :care_progress, array: true, default: [true, false, false, false, false, false, false, false, false]
      t.date :procedure_date, null: false
      t.string :procedure_type, null: false, default: 'not_specified'
      t.string :services, array: true, default: []
      t.date :service_start
      t.date :intensive_service_end
      t.date :service_end
      t.string :care_status
      t.date :intake_date
      # t.boolean :care_request_accepted, default: false

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
