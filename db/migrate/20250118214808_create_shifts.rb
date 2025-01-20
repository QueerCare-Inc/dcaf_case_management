class CreateShifts < ActiveRecord::Migration[7.1]
  def change
    create_table :shifts do |t|
      t.string :name
      t.datetime :start_time
      t.datetime :end_time
      t.string :support_type, null: false
      t.boolean :confirmed
      t.string :source, null: false
      t.boolean :fulfilled
      
      t.references :can_support, polymorphic: true

      t.timestamps
    end
  end
end
