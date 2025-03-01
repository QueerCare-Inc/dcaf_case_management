class Region < ApplicationRecord
  acts_as_tenant :fund

  # Validations
  validates_uniqueness_to_tenant :name
  validates :name, presence: true, length: { maximum: 150 }
  #  validates :state, presence: false, length: { maximum: 30 }
end
