class RemoveDetailsFromArchivedPatients < ActiveRecord::Migration[7.1]
  def change
    remove_column :archived_patients, :last_menstrual_period_weeks, :integer
    remove_column :archived_patients, :last_menstrual_period_days, :integer
    remove_column :archived_patients, :procedure_cost, :integer
    remove_column :archived_patients, :patient_contribution, :integer
    remove_column :archived_patients, :naf_pledge, :integer
    remove_column :archived_patients, :fund_pledge, :integer
    remove_column :archived_patients, :fund_pledged_at, :datetime
    remove_column :archived_patients, :pledge_sent, :boolean
    remove_column :archived_patients, :resolved_without_fund, :boolean
    remove_column :archived_patients, :pledge_generated_at, :datetime
    remove_column :archived_patients, :pledge_sent_at, :datetime
    remove_column :archived_patients, :pledge_generated_by_id, :bigint
    remove_column :archived_patients, :pledge_sent_by_id, :bigint
    remove_column :archived_patients, :ultrasound_cost, :integer
    remove_column :archived_patients, :solidarity_lead, :string
  end
end
