class DropExternalPledges < ActiveRecord::Migration[7.1]
  def change
    drop_table :external_pledges
  end
end
