class AddSessionValidityTokenToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :session_validity_token, :string
  end
end
