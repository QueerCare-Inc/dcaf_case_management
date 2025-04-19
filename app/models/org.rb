class Org < ApplicationRecord
  # TODO: make papertrailable

  # Relations
  has_many :regions
  has_many :people
  has_many :users
  has_many :patients
  has_many :volunteers
  has_many :care_coordinators

  # Validations
  validates :name,
            :subdomain,
            :domain,
            :full_name,
            :site_domain,
            :phone,
            presence: true
  validates :name, :subdomain, uniqueness: true

  def delete_patient_related_data
    [Patient,
     ArchivedPatient,
     Note,
     Fulfillment,
     PracticalSupport,
     Call].each do |model|
      model.destroy_all
    end
  end

  def delete_administrative_data
    [Clinic, Config, Region, User].each do |model|
      model.destroy_all
    end
  end
end
