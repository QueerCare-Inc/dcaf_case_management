# Indicator that a pledge by the primary org was cashed in,
# which in turn indicates that the patient used our pledged money.
class Fulfillment < ApplicationRecord
  acts_as_tenant :org

  # Concerns
  include PaperTrailable

  # Relationships
  belongs_to :can_fulfill, polymorphic: true
end
