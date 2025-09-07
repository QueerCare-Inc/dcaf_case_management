class Org < ApplicationRecord
  # TODO: make papertrailable
  include PhoneCleanable

  # Relations
  has_many :regions
  has_many :people
  has_many :users
  has_many :patients
  has_many :volunteers
  has_many :care_coordinators

  before_save :clean_org_phone_number 

  # Validations
  validates :name,
            :subdomain,
            :domain,
            :full_name,
            :site_domain,
            :phone_number,
            presence: true
  validates :phone_number, presence: true, phone: { possible: true, allow_blank: false }
  validates :name, :subdomain, uniqueness: true

  def delete_patient_related_data
    [Patient,
     ArchivedPatient,
     Note,
     Fulfillment,
     Procedure
    #  Call #ToDo: replace with care coordinate information
    ].each do |model|
      model.destroy_all
    end
  end

  def delete_administrative_data
    [Clinic, Config, Region, User].each do |model|
      model.destroy_all
    end
  end

  def clean_org_phone_number
    self.phone_number = clean_phone_number(phone_number)
  end
end
