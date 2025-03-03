# Allows models to have changed logged on create
module EventLoggable
  extend ActiveSupport::Concern

  included do
    after_create -> { log_event(event_params) }, if: :call?
  end

  def log_event(params = {})
    Event.create!(params)
  end

  private

  def call?
    is_a?(Call) && can_call.is_a?(Patient)
  end
end
