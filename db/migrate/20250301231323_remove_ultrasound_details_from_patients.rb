class RemoveUltrasoundDetailsFromPatients < ActiveRecord::Migration[7.2]
  def change
    remove_column :patients, :completed_ultrasound, :boolean
    remove_column :patients, :ultrasound_cost, :integer

    remove_column :archived_patients, :ultrasound_cost, :integer
  end
end
