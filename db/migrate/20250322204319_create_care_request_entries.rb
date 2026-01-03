class CreateCareRequestEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :care_request_entries do |t|
      # t.references :user, foreign_key: true
      # t.references :person, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.references :procedure, null: false, foreign_key: true
      t.references :care_coordinator, foreign_key: true
      t.references :org, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true
      # t.integer :order_key, null: false
      # t.string :region, null: false

      t.timestamps
    end
    add_index :care_request_entries, [:procedure_id, :patient_id, :care_coordinator_id, :org_id], unique: true
  end
end
