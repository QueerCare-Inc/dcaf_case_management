class CreateReimbursements < ActiveRecord::Migration[7.2]
  def change
    create_table :reimbursements do |t|
      t.timestamps

      # belongs to
      t.string :region, null: false
      t.references :region, foreign_key: true, null: false
      t.references :patient, foreign_key: true, null: false
      t.references :org, foreign_key: true, null: false
      # t.references :procedure, foreign_key: true

      # t.belongs_to :patient #redundant??

      # attributes
      t.date :date, null: false
      t.string :type, null: false
      t.string :amount, null: false
      t.string :status
    end
    add_index :reimbursements, :date
    add_index :reimbursements, :type
    add_index :reimbursements, :status
  end
end
