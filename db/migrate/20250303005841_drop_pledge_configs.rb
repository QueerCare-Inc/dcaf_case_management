class DropPledgeConfigs < ActiveRecord::Migration[7.2]
  def change
    drop_table pledge_config
  end
end
