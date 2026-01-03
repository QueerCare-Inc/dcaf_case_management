class CreateCareAddressess < ActiveRecord::Migration[7.2]
  def change
    create_table :care_addresses do |t|
      t.timestamps

      # belongs to
      t.references :region, foreign_key: true, null: false
      t.references :patient, foreign_key: true, null: false
      t.references :org, foreign_key: true, null: false
      # QC housing
      # procedure #reference added later

      # t.belongs_to :patient #redundant??

      # attributes
      t.text :street_address, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip
      t.text :phone_number, null: false
      t.text :start_date, null: false
      t.text :end_date, null: false
      t.boolean :confirmed, default: false
      t.numeric :coordinates, array: true, default: []
      t.boolean :qc_house, default: false
      t.string :closest_cross_street
      t.string :accessibility_options, array: true, default: []
      
      # has many
      # shifts
    end
    add_index :care_addresses, [:start_date, :coordinates, :org_id, :patient_id], unique: true
    add_index :care_addresses, :city
    add_index :care_addresses, :state
    add_index :care_addresses, :start_date
    add_index :care_addresses, :confirmed
    add_index :care_addresses, :qc_house
  end
end
