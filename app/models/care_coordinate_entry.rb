# Object representing a care coordinate list.
class CareCoordinateEntry < ApplicationRecord
  # acts_as_tenant :org

  # # Relationships
  # belongs_to :user
  # belongs_to :person
  # belongs_to :patient
  # belongs_to :region
  # belongs_to :care_coordinator
  # belongs_to :procedure

  # # Validations
  # validates :order_key, :region, presence: true
  # validates_uniqueness_to_tenant :procedure, scope: :user
end
