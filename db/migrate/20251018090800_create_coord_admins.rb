class CreateCoordAdmins < ActiveRecord::Migration[7.2]
  def change
    create_table :coord_admins do |t|
      t.timestamps

      # belongs to
      t.references :user, foreign_key: true
      t.references :person, foreign_key: true, null: false
      t.references :region, foreign_key: true
      t.references :org, foreign_key: true

    end
    add_index :coord_admins, [:person_id, :region_id, :org_id], unique: true
  end
end
