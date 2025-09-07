class CreatePeople < ActiveRecord::Migration[7.2]
  def change
    create_table :people do |t|
      t.timestamps

      # belongs to
      t.references :user, foreign_key: true #, null: false 
      #allow for new patients to be created without a user id (to be linked later)
      t.references :region, foreign_key: true
      t.references :org, foreign_key: true
      
      # new
      t.string :identifier
      t.string :emergency_contact
      t.string :emergency_contact_phone, limit: 15
      t.string :emergency_contact_relationship
      t.string :language
      t.integer :age
      t.string :city
      t.string :state
      t.string :zipcode
      t.string :race_ethnicity
      t.string :employment_status
      t.integer :household_size_children
      t.integer :household_size_adults
      t.string :income
      t.string :person_status
      t.string :special_circumstances, array: true, default: []
      t.boolean :textable
    end
    add_index :people, [:user_id, :region_id, :org_id]
    add_index :people, :identifier
  end
end
