class RemovePledgeDetailsFromPatients < ActiveRecord::Migration[7.2]
  def change
    remove_column :patients, :fund_pledged_at, :datetime
    remove_column :patients, :pledge_sent, :boolean
    remove_column :patients, :pledge_generated_at, :datetime
    remove_column :patients, :pledge_sent_at, :datetime
    # remove_column :patients, :pledge_generated_by_id, :bigint
    remove_reference :patients, :pledge_generated_by
    # remove_column :patients, :pledge_sent_by_id, :bigint
    remove_reference :patients, :pledge_sent_by
    remove_column :patients, :resolved_without_fund, :boolean
    remove_column :patients, :solidarity, :boolean
    remove_column :patients, :solidarity_lead, :string
    remove_column :patients, :procedure_cost, :integer

    remove_column :archived_patients, :fund_pledged_at, :datetime
    remove_column :archived_patients, :pledge_sent, :boolean
    remove_column :archived_patients, :pledge_generated_at, :datetime
    remove_column :archived_patients, :pledge_sent_at, :datetime
    # remove_column :archived_patients, :pledge_generated_by_id, :bigint
    remove_reference :archived_patients, :pledge_generated_by
    # remove_column :archived_patients, :pledge_sent_by_id, :bigint
    remove_reference :archived_patients, :pledge_sent_by
    remove_column :archived_patients, :resolved_without_fund, :boolean
    remove_column :archived_patients, :solidarity, :boolean
    remove_column :archived_patients, :solidarity_lead, :string
    remove_column :archived_patients, :procedure_cost, :integer
    
    remove_column :clinics, :email_for_pledges, :string

    remove_column :events, :pledge_amount, :integer
  end
end
