class CreateCareAddressess < ActiveRecord::Migration[7.2]
  def change
    create_table :care_addresses do |t|
      t.timestamps

      # belongs to
      t.string :region, null: false
      t.references :region, foreign_key: true, null: false
      t.references :patient, foreign_key: true, null: false
      t.references :org, foreign_key: true, null: false
      # QC housing
      # procedure

      # t.belongs_to :patient #redundant??

      # attributes
      t.string :street_address, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip
      t.string :phone, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.boolean :confirmed
      t.numeric :coordinates, array: true
      t.boolean :qc_house
      t.string :closest_cross_street

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
