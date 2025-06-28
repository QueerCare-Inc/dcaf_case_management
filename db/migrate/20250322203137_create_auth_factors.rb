class CreateAuthFactors < ActiveRecord::Migration[7.2]
  def change
    create_table :auth_factors do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :channel
      t.boolean :enabled, default: false
      t.boolean :registration_complete, default: false
      t.string :external_id
      t.string :phone_number, limit: 15 # E.164 format max length is 15
      t.string :email

      t.timestamps
    end
    add_index :auth_factors, %i[name user_id], unique: true
  end
end
