class CreateShifts < ActiveRecord::Migration[7.2]
  def change
    create_table :shifts do |t|
      t.timestamps

      # belongs to
      t.string :region #, null: false
      t.references :region, foreign_key: true, null: false
      t.references :procedure, foreign_key: true, null: false
      t.references :patient, foreign_key: true, null: false
      t.references :care_address, foreign_key: true, null: false
      t.references :org, foreign_key: true, null: false

      # t.belongs_to :procedure #redundant??
      # t.belongs_to :care_address #redundant??
      
      # attributes
      t.integer :shift_type, null: false
      t.string :services, array: true, default: []
      t.text :start_time
      t.text :end_time

      # has many
      # volunteers
    end
    add_index :shifts, [:procedure_id, :care_address_id, :org_id, :shift_type, :start_time], unique: true
    # add_index :shifts, :shift_type
    # add_index :shifts, :services
    # add_index :shifts, :start_time
  end
end
