class CreateCalls < ActiveRecord::Migration[7.2]
  def change
    create_table :calls do |t|
      t.integer :status, null: false

      t.references :can_call, polymorphic: true, null: false
      t.references :org, foreign_key: true
      t.timestamps
    end
  end
end
