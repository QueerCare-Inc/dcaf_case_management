class AddEndTimeToPracticalSupports < ActiveRecord::Migration[7.1]
  def change
    add_column :practical_supports, :end_time, :datetime
  end
end
