class ChangePatients < ActiveRecord::Migration[7.1]
  def change
    rename_column :patients, :other_contact, :emergency_conctact
    rename_column :patients, :other_phone, :emergency_contact_phone
    rename_column :patients, :other_contact_relationship, :emergency_contact_relationship
  end
end
