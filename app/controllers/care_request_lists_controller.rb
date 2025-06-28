# Controller for managing a user's care request list.
class CareRequestListsController < ApplicationController
  include RegionsHelper

  before_action :retrieve_care_requests, only: [:add_care_request, :remove_care_request]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }

  # ToDo: update locals table_type based on care status
  def add_care_request(care_status)
    current_user.add_care_request @care_request
    respond_to do |format|
      format.js { render template: 'users/refresh_care_requests', layout: false }#, locals: {care_status: care_status} }
    end
  end

  def remove_care_request(care_status)
    current_user.remove_care_request @care_request
    respond_to do |format|
      format.js { render template: 'users/refresh_care_requests', layout: false }#, locals: {care_status: care_status} }
    end
  end

  def clear_current_user_care_request_list(care_status)
    current_user.clear_care_request_list current_region
    respond_to do |format|
      format.js { render template: 'users/refresh_care_requests', layout: false }#, locals: {care_status: care_status} }
    end
  end

  def reorder_care_request_list
    current_user.reorder_care_request_list params[:order], current_region
    head :ok
  end

  private

  def retrieve_care_requests
    # ToDo: this might need to be updated to CareRequest
    @care_request = Procedure.find params[:id]
  end
end