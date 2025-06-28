# Object representing a care coordinate list.
class CareRequestEntry < ApplicationRecord
  acts_as_tenant :org

  # Relationships
  belongs_to :region
  belongs_to :procedure

  # # Validations
  validates :order_key, :procedure_date, :region, presence: true
  validates_uniqueness_to_tenant :procedure, scope: :patient
  # ToDo: revisit this last line. I'm not certain this is the correct translation.
end
