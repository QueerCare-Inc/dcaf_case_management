class AddDetailsToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :legal_name, :string #, null: false
    add_column :patients, :email, :string #, null: false
    add_column :patients, :emergency_reference_wording, :string
    add_column :patients, :in_case_of_emergency, :string, default: [], array: true
  end
end
