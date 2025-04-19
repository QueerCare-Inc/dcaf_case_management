class CreateConfigs < ActiveRecord::Migration[7.2]
  def change
    create_table :configs do |t|
      t.integer :config_key, null: false
      t.jsonb :config_value, default: { options: [] }, null: false
      t.references :org, foreign_key: true

      t.timestamps
    end

    add_index :configs, [:config_key, :org_id], unique: true
  end 
end
