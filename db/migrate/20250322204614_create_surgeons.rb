class CreateSurgeons < ActiveRecord::Migration[7.2]
  def change
    create_table :surgeons do |t|
      t.timestamps

      # belongs to
      t.string :region, null: false
      t.references :region, foreign_key: true, null: false
      t.references :org, foreign_key: true, null: false

      # attributes
      t.string :name, null: false
      t.string :email
      t.string :phone, null: false
      t.string :procedure_types, array: true, default: []
      t.string :insurances, array: true, default: []

      t.boolean :active, null: false, default: true

      # has many
      # procedures, clinics
    end
    add_index :surgeons, [:name, :org_id], unique: true
    add_index :surgeons, :procedure_types
    add_index :surgeons, :insurances
    add_index :surgeons, :active
  end
end
