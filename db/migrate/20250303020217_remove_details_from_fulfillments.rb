class RemoveDetailsFromFulfillments < ActiveRecord::Migration[7.2]
  def change
    remove_column :fulfillments, :gestation_at_procedure, :integer
    remove_column :fulfillments, :fund_payout, :integer
    remove_column :fulfillments, :check_number, :string
    remove_column :fulfillments, :date_of_check, :date
  end
end
