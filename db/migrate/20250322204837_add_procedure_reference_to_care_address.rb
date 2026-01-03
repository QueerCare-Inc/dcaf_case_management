class AddProcedureReferenceToCareAddress < ActiveRecord::Migration[7.2]
  def change
    add_reference :care_addresses, :procedure, foreign_key: true, null: false
    add_index :care_addresses, [:procedure_id, :street_address, :city, :state, :zip, :start_date, :end_date], unique: true, name: 'index_care_addresses_on_procedure_and_address'
  end
end
