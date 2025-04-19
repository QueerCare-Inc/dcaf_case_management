class Region < ApplicationRecord
  acts_as_tenant :org

  # Validations
  validates_uniqueness_to_tenant :name
  validates :name, presence: true, length: { maximum: 150 }
  validates :state, presence: false, length: { maximum: 30 }

  has_many :people
  has_many :users
  has_many :patients
  has_many :volunteers
  has_many :care_coordinators
end
