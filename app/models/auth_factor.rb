# frozen_string_literal: true

# An authentication factor used for multi factor authentication.
class AuthFactor < ApplicationRecord
  include PaperTrailable
  include PhoneCleanable

  cattr_accessor :form_steps do
    [:registration, :verification, :confirmation]
  end
  attr_accessor :current_form_step

  before_validation :clean_fields
  before_save :clean_auth_factor_phone_number #, if: :phone_number_changed?


  belongs_to :user

  CHANNELS = [
    SMS = 'sms'
  ].freeze

  CHANNELS.each do |channel|
    scope channel, -> { where(channel: channel) }
  end

  validates :channel, presence: true, inclusion: { in: CHANNELS }

  with_options if: -> { past_step?(:registration) } do
    validates :name, presence: true, uniqueness: { scope: :user_id }, length: { maximum: 30 }
    # validates :phone, presence: true, format: /\A\d{10}\z/, length: { is: 10 }
    validates :phone_number, presence: true, phone: { possible: true, allow_blank: false } #, length: { is: 10}
  end

  private

  def clean_fields
    phone_number&.gsub!(/\D/, '')
    name&.strip!
  end

  # Returns true if the current step is on or past the input step.
  def past_step?(step)
    # If the form is complete, there will be no current step.
    return true if current_form_step.nil?

    return true if form_steps.index(current_form_step) >= form_steps.index(step)
  end

  def clean_auth_factor_phone_number
    self.phone_number = clean_phone_number(phone_number)
  end
end
