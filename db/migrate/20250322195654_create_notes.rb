class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.string :full_text, null: false

      t.references :patient
      t.references :org, foreign_key: true
      t.references :can_note, polymorphic: true, null: true

      t.timestamps
    end
  end
end
