class AddProcedureReferenceToCareAddress < ActiveRecord::Migration[7.2]
  def change
    add_reference :care_addresses, :procedure, foreign_key: true, null: false
  end
end
