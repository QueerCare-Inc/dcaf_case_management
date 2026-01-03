class AddCareRequestEntryToProcedures < ActiveRecord::Migration[7.2]
  def change
    add_column :procedures, :care_request_entry_id, :integer #, null: false
    add_foreign_key :procedures, :care_request_entries
  end
end
