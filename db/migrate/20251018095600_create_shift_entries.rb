class CreateShiftEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :shift_entries do |t|
      t.references :region, foreign_key: true
      t.references :org, foreign_key: true
      t.references :care_coordinator, foreign_key: true
      t.references :patient, foreign_key: true
      t.references :volunteer, foreign_key: true
      t.references :procedure, foreign_key: true
      t.references :care_address, foreign_key: true
      t.references :shift, foreign_key: true

      t.timestamps
    end
  end
end