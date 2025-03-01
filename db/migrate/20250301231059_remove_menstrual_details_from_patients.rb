class RemoveMenstrualDetailsFromPatients < ActiveRecord::Migration[7.2]
  def change
    remove_column :patients, :last_menstrual_period_days, :integer
    remove_column :patients, :last_menstrual_period_weeks, :integer

    remove_column :archived_patients, :last_menstrual_period_days, :integer
    remove_column :archived_patients, :last_menstrual_period_weeks, :integer
  end
end
