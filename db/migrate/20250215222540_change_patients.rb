class ChangePatients < ActiveRecord::Migration[7.1]
  def change
    rename_column :patients, :other_contact, :emergency_contact
    rename_column :patients, :other_phone, :emergency_contact_phone
    rename_column :patients, :other_contact_relationship, :emergency_contact_relationship

    rename_column :patients, :appointment_date, :procedure_date
    rename_column :archived_patients, :appointment_date, :procedure_date
  end
end
