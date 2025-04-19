class CreateSurgeonsClinics < ActiveRecord::Migration[7.2]
  def change
    # Create a join table to establish the many-to-many relationship between surgeons and clinics.
    create_table :surgeons_clinics do |t|
      # creates foreign keys linking the join table to the 'surgeons' and 'clinics' tables
      t.belongs_to :surgeon
      t.belongs_to :clinic
    end
  end
end
