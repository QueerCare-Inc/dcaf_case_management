class RenameInitialCallDateAsIntakeDate < ActiveRecord::Migration[7.2]
  def change
    rename_column :archived_patients, :initial_call_date, :intake_date
    rename_column :patients, :initial_call_date, :intake_date
  end
end
