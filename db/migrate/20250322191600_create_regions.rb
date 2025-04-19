class CreateRegions < ActiveRecord::Migration[7.2]
  def change
    create_table :regions do |t|
      t.string :name, null: false
      t.references :org, null: false, foreign_key: true
      t.string :state
      
      t.timestamps
    end
    add_index :regions, [:name, :org_id], unique: true
  end
end
