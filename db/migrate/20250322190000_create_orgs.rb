class CreateOrgs < ActiveRecord::Migration[7.2]
  def change
    create_table :orgs do |t|
      t.string :name
      t.string :subdomain
      t.string :domain

      t.string :full_name, comment: 'Full name of the organization. e.g. DC Abortion Fund'
      t.string :site_domain, comment: "URL of the organization's public-facing website. e.g. www.dcabortionfund.org"
      t.string :phone, comment: 'Contact number for the organization, usually the hotline'
      
      t.timestamps
    end
  end
end
