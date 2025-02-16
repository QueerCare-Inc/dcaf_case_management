class RemoveDetailsFromFulfillments < ActiveRecord::Migration[7.1]
  def change
    remove_column :fulfillments, :gestation_at_procedure, :integer
    remove_column :fulfillments, :fund_payout, :integer
  end
end
