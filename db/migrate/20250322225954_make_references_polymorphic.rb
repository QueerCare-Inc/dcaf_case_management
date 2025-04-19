class MakeReferencesPolymorphic < ActiveRecord::Migration[7.2]
  def change
    add_reference :shifts, :can_shift, polymorphic: true, null: true
    add_reference :patients, :can_patient, polymorphic: true, null: true
    add_reference :care_addresses, :can_care_address, polymorphic: true, null: true
    add_reference :reimbursements, :can_reimburse, polymorphic: true, null: true
    add_reference :procedures, :can_procedure, polymorphic: true, null: true
    # add_reference :volunteers, :can_volunteer, polymorphic: true, null: true
    # add_reference :clinics, :can_clinic, polymorphic: true, null: true
  end
end
