class RemoveDetailsFromClinics < ActiveRecord::Migration[7.2]
  def change
    remove_column :clinics, :gestational_limit, :integer
    remove_column :clinics, :costs_5wks, :integer
    remove_column :clinics, :costs_6wks, :integer
    remove_column :clinics, :costs_7wks, :integer
    remove_column :clinics, :costs_8wks, :integer
    remove_column :clinics, :costs_9wks, :integer
    remove_column :clinics, :costs_10wks, :integer
    remove_column :clinics, :costs_11wks, :integer
    remove_column :clinics, :costs_12wks, :integer
    remove_column :clinics, :costs_13wks, :integer
    remove_column :clinics, :costs_14wks, :integer
    remove_column :clinics, :costs_15wks, :integer
    remove_column :clinics, :costs_16wks, :integer
    remove_column :clinics, :costs_17wks, :integer
    remove_column :clinics, :costs_18wks, :integer
    remove_column :clinics, :costs_19wks, :integer
    remove_column :clinics, :costs_20wks, :integer
    remove_column :clinics, :costs_21wks, :integer
    remove_column :clinics, :costs_22wks, :integer
    remove_column :clinics, :costs_23wks, :integer
    remove_column :clinics, :costs_24wks, :integer
    remove_column :clinics, :costs_25wks, :integer
    remove_column :clinics, :costs_26wks, :integer
    remove_column :clinics, :costs_27wks, :integer
    remove_column :clinics, :costs_28wks, :integer
    remove_column :clinics, :costs_29wks, :integer
    remove_column :clinics, :costs_30wks, :integer
  end
end
