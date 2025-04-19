class CreateProcedures < ActiveRecord::Migration[7.2]
  def change
    create_table :procedures do |t|
      t.timestamps

      # belongs to
      t.string :region, null: false
      t.references :region, foreign_key: true, null: false
      t.references :person, foreign_key: true, null: false
      t.references :patient, foreign_key: true, null: false
      t.references :org, foreign_key: true, null: false
      # t.references :clinic, foreign_key: true, null: false
      ## surgeon

      # t.belongs_to :patient #redundant??

      # attributes
      t.date :procedure_date, null: false
      t.string :type, null: false
      t.string :services, array: true, default: []
      t.date :service_start
      t.date :intensive_service_end
      t.date :service_end
      t.string :status

      # has many
      # care addresses, shifts, reimbursements
    end
    add_index :procedures, [:patient_id, :procedure_date], unique: true
    add_index :procedures, :type
    add_index :procedures, :services
    add_index :procedures, :service_start
    add_index :procedures, :status
  end
end
