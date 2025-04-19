class CreatePeople < ActiveRecord::Migration[7.2]
  def change
    create_table :people do |t|
      t.timestamps

      # belongs to
      t.references :user, foreign_key: true, null: false
      t.references :region, foreign_key: true
      t.references :org, foreign_key: true

      # t.belongs_to :user #redundant??

      # # from user
      # [
      #   :name, :email, :primary_phone, :pronouns, :id
      # ].each do |clm|
      #   t.references :user, foreign_key: { to_table: :user, column: clm} 
      # end

      # new
      t.string :identifier
      t.string :emergency_contact
      t.string :emergency_contact_phone
      t.string :emergency_contact_relationship
      # t.string :region #, null: false
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
      t.string :status
      t.string :special_circumstances, array: true, default: []
      t.boolean :textable
    end
    add_index :people, [:user_id, :region_id, :org_id], unique: true
    # add_index :people, :name
    # add_index :people, :emergency_contact_phone
    # add_index :people, :emergency_contact
    add_index :people, :identifier
  end
end
