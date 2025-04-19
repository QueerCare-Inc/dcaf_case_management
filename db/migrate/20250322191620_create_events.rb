class CreateEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :events do |t|
      # t.string :care_coordinator_name
      t.integer :event_type
      # t.string :region
      t.string :patient_name
      t.string :patient_id
      t.references :org, foreign_key: true
      t.references :region, foreign_key: true

      t.timestamps
    end

    add_index :events, :created_at
    # add_index :events, :region
  end
end
