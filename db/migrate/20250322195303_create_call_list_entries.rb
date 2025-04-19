class CreateCallListEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :call_list_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.references :org, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true

      t.string :region, null: false
      t.integer :order_key, null: false

      t.timestamps
    end
    add_index :call_list_entries, [:patient_id, :person_id, :user_id, :org_id], unique: true
  end
end
