class CreateQcHousings < ActiveRecord::Migration[7.2]
  def change
    create_table :qc_housings do |t|
      t.timestamps

      # belongs to 
      t.string :region, null: false
      t.references :region, foreign_key: true, null: false
      t.references :volunteer, foreign_key: true, null: false
      t.references :org, foreign_key: true, null: false

      # t.belongs_to :volunteer #redundant??

      # attributes
      t.string :street_address, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip
      t.string :closest_cross_street
      t.string :phone, null: false
      t.numeric :coordinates, array: true

      t.string :accessability
      t.string :availabilities, array: true, default: []

      # has many
      # t.references :care_addresses, array: true, default: []
      
    end
    add_index :qc_housings, [:coordinates, :org_id], unique: true
    add_index :qc_housings, :availabilities
    add_index :qc_housings, :city
    add_index :qc_housings, :state
  end
end
