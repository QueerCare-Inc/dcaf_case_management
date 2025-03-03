class DropExternalPledges < ActiveRecord::Migration[7.2]
  def change
    drop_table :external_pledges
  end
end
