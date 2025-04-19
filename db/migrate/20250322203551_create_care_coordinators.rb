class CreateCareCoordinators < ActiveRecord::Migration[7.2]
  def change
    create_table :care_coordinators do |t|
      t.timestamps

      # belongs to
      t.references :user, foreign_key: true
      t.references :person, foreign_key: true, null: false
      t.references :region, foreign_key: true
      t.references :org, foreign_key: true

      # t.belongs_to :user #redundant??
      # t.belongs_to :person #redundant??

      # # from user
      # [
      #   :name, :email, :primary_phone, :pronouns, :id
      # ].each do |clm|
      #   t.references :user, foreign_key: { to_table: :user, column: clm} 
      # end

      # # from person
      # [
      #   :identifier, :id,
      #   :emergency_contact, :emergency_contact_phone,
      #   :emergency_contact_relationship, :region,
      #   :language, :age, :city, :state, :zipcode,
      #   :race_ethnicity, :employment_status,
      #   :household_size_children, :household_size_adults,
      #   :income, :status, :special_circumstances, :textable
      # ].each do |clm|
      #   t.references :person, foreign_key: { to_table: :person, column: clm} 
      # end

      # Same information as volunteers
      # t.string :region
      t.string :volunteer_types, array: true, default: []
      t.boolean :textable
      
      # has many
      # patients

    end
    add_index :care_coordinators, [:person_id, :region_id, :org_id], unique: true
    # add_index :care_coordinators, :name
    # add_index :care_coordinators, :emergency_contact_phone
    # add_index :care_coordinators, :emergency_contact
    # add_index :care_coordinators, :identifier
  end
end
