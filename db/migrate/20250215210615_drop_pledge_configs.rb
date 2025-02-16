class DropPledgeConfigs < ActiveRecord::Migration[7.1]
  def change
    drop_table :pledge_configs
  end
end
