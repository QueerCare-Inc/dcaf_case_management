class CreateFulfillment < ActiveRecord::Migration[7.2]
  def change
    create_table :fulfillments do |t|
      t.boolean :fulfilled, null: false, default: false
      t.date :procedure_date
      t.boolean :audited

      t.references :can_fulfill, polymorphic: true, null: false
      t.references :org, foreign_key: true
      t.timestamps
    end

    add_index :fulfillments, :fulfilled
    add_index :fulfillments, :audited
  end
end
