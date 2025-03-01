class AddTimesToPracticalSupports < ActiveRecord::Migration[7.2]
  def change
    add_column :practical_supports, :start_time, :datetime
    add_column :practical_supports, :end_time, :datetime

    remove_column practical_supports, :support_date, :date
  end
end
