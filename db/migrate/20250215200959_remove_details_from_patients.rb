class RemoveDetailsFromPatients < ActiveRecord::Migration[7.1]
  def change
    remove_column :patients, :procedure_cost, :integer
    remove_column :patients, :patient_contribution, :integer
    remove_column :patients, :naf_pledge, :integer
    remove_column :patients, :fund_pledge, :integer
    remove_column :patients, :fund_pledged_at, :datetime
    remove_column :patients, :pledge_sent, :boolean
    remove_column :patients, :resolved_without_fund, :boolean
    remove_column :patients, :pledge_generated_at, :datetime
    remove_column :patients, :pledge_sent_at, :datetime
    remove_column :patients, :pledge_generated_by_id, :bigint
    remove_column :patients, :pledge_sent_by_id, :bigint
    remove_column :patients, :ultrasound_cost, :integer
    remove_column :patients, :solidarity, :boolean
    remove_column :patients, :solidarity_lead, :string
    remove_column :patients, :completed_ultrasound, :boolean
    remove_column :patients, :referred_to_clinic, :boolean
    remove_column :patients, :practical_support_waiver, :boolean
    remove_column :patients, :county, :string
    # remove_index :patients, :index_patients_on_pledge_generated_by_id
    # remove_column :patients, :index_patients_on_pledge_generated_by_id, :string
    # remove_index :patients, :index_patients_on_pledge_sent
    # remove_column :patients, :index_patients_on_pledge_sent, :string
  end
end
