class PortLinesToRegions < ActiveRecord::Migration[7.2]
  def change
    [:archived_patients, :call_list_entries, :events, :patients].each do |tbl|
      add_reference tbl, :region, foreign_key: true, null: false
      remove_reference tbl, :line
    end

    # add_reference :users, :region, foreign_key: true #, null: false
    # remove_column :users, :line
    rename_column :users, :line, :region
  end
end
