class CreateShiftsVolunteers < ActiveRecord::Migration[7.2]
  def change
    # Create a join table to establish the many-to-many relationship between shifts and volunteers.
    create_table :shifts_volunteers do |t|
      t.belongs_to :shift
      t.belongs_to :clinic
    end
  end
end
