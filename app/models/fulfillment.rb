# Indicator that a pledge by the primary fund was cashed in,
# which in turn indicates that the patient used our pledged money.
class Fulfillment < ApplicationRecord
  acts_as_tenant :fund

  # Concerns
  include PaperTrailable

  # Relationships
  belongs_to :can_fulfill, polymorphic: true
end
