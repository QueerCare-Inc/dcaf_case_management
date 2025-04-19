class CreateClinics < ActiveRecord::Migration[7.2]
  def change
    create_table :clinics do |t|
      t.string :name, null: false
      t.string :street_address
      t.string :city
      t.string :state
      t.string :zip
      t.string :phone
      t.string :fax
      t.boolean :active, null: false, default: true
      t.boolean :accepts_medicaid
      t.numeric :coordinates, array: true

      t.references :org, foreign_key: true
      t.references :region, foreign_key: true

      t.timestamps
    end

    add_index :clinics, [:name, :org_id], unique: true
  end
end
