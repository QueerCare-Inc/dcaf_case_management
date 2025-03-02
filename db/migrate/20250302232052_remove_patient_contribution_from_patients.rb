class RemovePatientContributionFromPatients < ActiveRecord::Migration[7.2]
  def change
    remove_column :patients, :patient_contribution, :integer
    remove_column :archived_patients, :patient_contribution, :integer
  end
end
