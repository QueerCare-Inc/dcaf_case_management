class CreateShifts < ActiveRecord::Migration[7.2]
  def change
    create_table :shifts do |t|
      t.timestamps

      # belongs to
      t.string :region, null: false
      t.references :region, foreign_key: true, null: false
      t.references :procedure, foreign_key: true, null: false
      t.references :patient, foreign_key: true, null: false
      t.references :care_address, foreign_key: true, null: false
      t.references :org, foreign_key: true, null: false

      # t.belongs_to :procedure #redundant??
      # t.belongs_to :care_address #redundant??
      
      # attributes
      t.string :type, null: false
      t.string :services, array: true, default: []
      t.datetime :start_time
      t.datetime :end_time

      # has many
      # volunteers
    end
    add_index :shifts, [:care_address_id, :org_id], unique: true
    add_index :shifts, :type
    add_index :shifts, :services
    add_index :shifts, :start_time
  end
end
