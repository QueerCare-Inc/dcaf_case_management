# Controller for managing a user's care request list.
class CareAddressListsController < ApplicationController
  include RegionsHelper

  before_action :retrieve_care_addresses, only: [:add_care_address, :remove_care_address]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }

  def add_care_address
    care_address_start_time = DateTime.parse(@care_address.start_time)
    care_address_end_time = DateTime.parse(@care_address.end_time)

    # Check for overlapping care addresses
    overlapping_care_address = CareAddress.where(procedure_id: current_procedure.id)
                                          .where.not(id: @care_address.id) # Exclude the current care address
                                          .where(
                                            'start_date <= ? AND end_date >= ?',
                                            care_address_end_time, care_address_start_time
                                          )
                                          .exists?
    if overlapping_care_address
      flash.now[:alert] = t('flash.overlapping_care_address', timestamp: Time.zone.now.display_timestamp)
      respond_to do |format|
        format.js { render template: 'care_addresses/refresh_care_addresses', layout: false }
      end
      return
    end

    # Add the care address if no overlap exists
    current_procedure.add_care_address @care_address
    respond_to do |format|
      format.js { render template: 'care_addresses/refresh_care_addresses', layout: false }
    end
  end

  def remove_care_address
    current_procedure.remove_care_address @care_address
    respond_to do |format|
      format.js { render template: 'care_addresses/refresh_care_addresses', layout: false }
    end
  end

  def clear_current_procedure_care_address_list
    current_procedure.clear_care_address_list current_region
    respond_to do |format|
      format.js { render template: 'users/refresh_care_addresses', layout: false }
    end
  end

  def reorder_care_address_list
    current_procedure.reorder_care_address_list params[:order], current_region
    head :ok
  end

  private

  def retrieve_care_addresses
    @procedure = Procedure.find procedure_params[:id]
    @care_address = CareAddress.find care_address_params[:id]
  end
end
