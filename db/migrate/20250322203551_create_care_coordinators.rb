class CreateCareCoordinators < ActiveRecord::Migration[7.2]
  def change
    create_table :care_coordinators do |t|
      t.timestamps

      # belongs to
      t.references :user, foreign_key: true
      t.references :person, foreign_key: true, null: false
      t.references :region, foreign_key: true
      t.references :org, foreign_key: true


      # Same information as volunteers
      t.integer :care_coordinator_status
      t.integer :volunteer_status
      t.string :volunteer_types, array: true, default: []
      t.boolean :textable
      
      # has many
      # patients

    end
    add_index :care_coordinators, [:person_id, :region_id, :org_id], unique: true
  end
end
