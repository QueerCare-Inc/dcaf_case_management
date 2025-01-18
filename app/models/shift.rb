# Object representing individual shift information.
class Shift < ApplicationRecord
  acts_as_tenant :fund

  encrypts :attachment_url

  # Concerns
  include PaperTrailable
  include Notetakeable

  # Relationships
  belongs_to :line
  belongs_to :patient
  has_many :users, through: :call_list_entries # revisit through here. It should have one CR and possibly many volunteers?
  belongs_to :can_support, polymorphic: true
  has_many :notes, as: :can_note

  # Validations
  validates :name, :source, :support_type, :start_time, :end_time, :filled, presence: true, length: { maximum: 150 }
  validates :filled, format: :boolean
end
