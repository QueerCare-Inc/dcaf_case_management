class CreateResources < ActiveRecord::Migration[7.2]
  def change
    create_table :resources do |t|
      t.timestamps

      t.string :regions, array: true, default: []
      t.string :website_link
      t.string :phone
      t.string :email
      t.string :contact_person
      t.string :services_provided
    end
  end
end
