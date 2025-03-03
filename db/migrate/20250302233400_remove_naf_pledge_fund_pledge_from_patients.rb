class RemoveNafPledgeFundPledgeFromPatients < ActiveRecord::Migration[7.2]
  def change
    remove_column :patients, :naf_pledge, :integer
    remove_column :patients, :fund_pledge, :integer
    
    remove_column :archived_patients, :naf_pledge, :integer
    remove_column :archived_patients, :fund_pledge, :integer

    remove_column :clinics, :accepts_naf, :boolean
  end
end
