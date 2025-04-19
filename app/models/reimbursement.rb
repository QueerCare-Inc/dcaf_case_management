# Object representing a clinic that a patient is going to.
class Reimbursement < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable

  encrypts :date
  encrypts :type
  encrypts :amount

  belongs_to :region
  belongs_to :patient
  has_one :procedure

  # Validations
  validates :date, :type, :amount, presence: true
  validates :date, :type, :amount,
            length: { maximum: 150 }

  # Methods
end
