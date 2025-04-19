# Object representing a patient's call list.
class CallListEntry < ApplicationRecord
  acts_as_tenant :org

  # Relationships
  belongs_to :user
  belongs_to :patient
  belongs_to :region

  # Validations
  validates :order_key, :region, presence: true
  validates_uniqueness_to_tenant :patient, scope: :user
end
