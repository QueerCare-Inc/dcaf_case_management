class AddStartTimeToPracticalSupports < ActiveRecord::Migration[7.1]
  def change
    add_column :practical_supports, :start_time, :datetime
  end
end
