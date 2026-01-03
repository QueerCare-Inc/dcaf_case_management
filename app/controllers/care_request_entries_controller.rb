# Controller for managing a user's care request list.
class CareRequestEntriesController < ApplicationController
  # include RegionsHelper

  before_action :confirm_cc_or_higher

  # before_action :retrieve_care_requests, only: [:add_care_request, :remove_care_request]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }

  before_action :set_care_request_entry, only: [:update]

  def index
    @care_request_entries = CareRequestEntry.all.sort_by { |c| [c.patient, c.procedure, c.care_coordinator] }
    respond_to do |format|
      format.html
    end
  end

  def create
    @care_request_entry = CareRequestEntry.create_care_request_entry(
      care_coordinator: CareCoordinator.find(params[:care_coordinator_id]),
      patient: Patient.find(params[:patient_id]),
      procedure: Procedure.find(params[:procedure_id])
    )

    # .new care_request_entry_params
    if @care_request_entry.save
      flash[:notice] = t('flash.care_request_entry_created')
      redirect_to care_request_entries_path
    else
      flash[:alert] =
        t('flash.error_saving_care_request_entry', error: @care_request_entry.errors.full_messages.to_sentence)
      render 'new'
    end
  end

  def update
    @care_request_entry = CareRequestEntry.find(params[:id])
    @user = @care_request_entry.patient.user
    @patient = @care_request_entry.patient
    @procedure = @care_request_entry.procedure

    # Extract nested parameters explicitly
    user_params = care_request_entry_params[:user]
    patient_params = care_request_entry_params[:patient]
    procedure_params = care_request_entry_params[:procedure]
    Rails.logger.debug "Current care coordinator user id: #{care_request_entry_params[:care_coordinator_id]}"
    # Handle care_coordinator_id as either a user_id or a valid care_coordinator_id
    if care_request_entry_params[:care_coordinator_id].present?
      care_coordinator_user_id = care_request_entry_params[:care_coordinator_id].to_i
      Rails.logger.debug "Converted care_coordinator_user_id: \\#{care_coordinator_user_id}"

      care_coordinator_id = if CareCoordinator.exists?(id: care_coordinator_user_id)
                              care_coordinator_user_id
                            else
                              # Check if it's a user_id
                              CareCoordinator.find_by(user_id: care_coordinator_user_id)&.id
                            end

      Rails.logger.debug "Mapped care_coordinator_id: \\#{care_coordinator_id}"

      # Use the care_coordinator_id if mapped, otherwise keep the original
      # care_request_entry_params[:care_coordinator_id] = care_coordinator_id.to_s
    end

    # Update the care request entry and associated models
    if @user.update(user_params) &&
       @patient.update(patient_params) &&
       @procedure.update(procedure_params) &&
       @care_request_entry.update(care_request_entry_params.except(:user, :patient, :procedure,
                                                                   :care_coordinator_id).merge(care_coordinator_id: care_coordinator_id)) &&
       @care_request_entry.update(care_coordinator_id: care_coordinator_id)

      flash.now[:notice] = t('flash.care_request_info_saved', timestamp: Time.zone.now.display_timestamp)
    else
      error = @user.errors.full_messages.to_sentence
      flash.now[:alert] = error
      error = @patient.errors.full_messages.to_sentence
      flash.now[:alert] = error
      error = @procedure.errors.full_messages.to_sentence
      flash.now[:alert] = error
      error = @care_request_entry.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end

    # Respond with JavaScript
    respond_to do |format|
      format.js # This renders app/views/care_request_entries/update.js.erb
    end
  end

  def destroy
    @care_request_entry = CareRequestEntry.find(params[:id])
    if @care_request_entry.remove_care_request_entry
      flash[:notice] = 'Care request entry removed successfully.'
    else
      flash[:alert] = 'Failed to remove care request entry.'
    end
    redirect_to care_request_entries_path
  end

  def update_care_coordinator
    Rails.logger.debug "update_care_coordinator action triggered for CareRequestEntry ID: #{params[:id]}"
    @care_request_entry = CareRequestEntry.find(params[:id])
    new_care_coordinator = CareCoordinator.find(params[:care_coordinator_id])

    ActiveRecord::Base.transaction do
      # Update the CareCoordinator for the Patient and Procedure
      @care_request_entry.patient.update!(care_coordinator: new_care_coordinator)
      @care_request_entry.procedure.update!(care_coordinator: new_care_coordinator)
      @care_request_entry.update!(care_coordinator: new_care_coordinator)
      @care_request_entry.procedure.update!(care_status: Procedure.care_statuses[:coordinator_assigned])
    end

    flash[:notice] = 'Care Coordinator updated successfully.'
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Failed to update Care Coordinator: #{e.message}"
  end

  def mark_intake_complete
    @care_request_entry = CareRequestEntry.find(params[:id])
    ActiveRecord::Base.transaction do
      @care_request_entry.procedure.update!(care_status: Procedure.care_statuses[:intake_complete])
    end
    flash[:notice] = 'Care request marked intake complete successfully.'
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Failed to mark intake complete: #{e.message}"
  end

  def mark_accepted
    @care_request_entry = CareRequestEntry.find(params[:id])
    ActiveRecord::Base.transaction do
      @care_request_entry.procedure.update!(care_status: Procedure.care_statuses[:accepted_care_request])
    end
    flash[:notice] = 'Care request marked as accepted successfully.'
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Failed to mark as accepted: #{e.message}"
  end

  def mark_procedure_confirmed
    @care_request_entry = CareRequestEntry.find(params[:id])
    ActiveRecord::Base.transaction do
      @care_request_entry.procedure.update!(care_status: Procedure.care_statuses[:procedure_confirmed])
    end
    flash[:notice] = 'Care request marked as procedure confirmed successfully.'
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Failed to mark as procedure confirmed: #{e.message}"
  end

  def mark_under_care
    @care_request_entry = CareRequestEntry.find(params[:id])
    ActiveRecord::Base.transaction do
      @care_request_entry.procedure.update!(care_status: Procedure.care_statuses[:under_care])
    end
    flash[:notice] = 'Care request marked as under care successfully.'
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Failed to mark as under care: #{e.message}"
  end

  def mark_care_complete
    @care_request_entry = CareRequestEntry.find(params[:id])
    ActiveRecord::Base.transaction do
      @care_request_entry.procedure.update!(care_status: Procedure.care_statuses[:care_complete])
    end
    flash[:notice] = 'Care request marked as care complete successfully.'
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Failed to mark as care complete: #{e.message}"
  end

  def mark_rejected
    @care_request_entry = CareRequestEntry.find(params[:id])
    ActiveRecord::Base.transaction do
      @care_request_entry.procedure.update!(care_status: Procedure.care_statuses[:rejected_care_request])
    end
    flash[:notice] = 'Care request marked as rejected successfully.'
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Failed to mark as rejected: #{e.message}"
  end

  def mark_archived
    @care_request_entry = CareRequestEntry.find(params[:id])
    ActiveRecord::Base.transaction do
      @care_request_entry.procedure.update!(care_status: Procedure.care_statuses[:archived])
    end
    flash[:notice] = 'Care request marked as archived successfully.'
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Failed to mark as archived: #{e.message}"
  end

  # # TODO: update locals table_type based on care status
  # def add_care_request(care_status)
  #   current_user.add_care_request @care_request
  #   respond_to do |format|
  #     format.js { render template: 'users/refresh_care_requests', layout: false }
  #   end
  # end

  # def remove_care_request(care_status)
  #   current_user.remove_care_request @care_request
  #   respond_to do |format|
  #     format.js { render template: 'users/refresh_care_requests', layout: false }
  #   end
  # end

  # def clear_current_user_care_request_list(care_status)
  #   current_user.clear_care_request_list current_region
  #   respond_to do |format|
  #     format.js { render template: 'users/refresh_care_requests', layout: false }
  #   end
  # end

  # def reorder_care_request_list
  #   current_user.reorder_care_request_list params[:order], current_region
  #   head :ok
  # end

  private

  # Set the care request entry
  def set_care_request_entry
    Rails.logger.debug "set_care_request_entry: params[:id] = #{params[:id]}"
    @care_request_entry = CareRequestEntry.find(params[:id])
    Rails.logger.debug "set_care_request_entry: Found CareRequestEntry with ID #{params[:id]}"
  end

  # Whitelist valid fields
  def valid_field?(field)
    %w[user[name] user[primary_phone] user[pronouns] user[email]
       patient[intake_date] procedure[procedure_date]].include?(field)
  end

  # Sanitize the value
  def sanitize_value(value)
    ActionController::Base.helpers.sanitize(value)
  end

  def care_request_entry_params
    params.require(:care_request_entry).permit(
      :procedure_id, :patient_id, :care_coordinator_id,
      user: [:name, :primary_phone, :pronouns, :email],
      patient: [:intake_date],
      procedure: [:procedure_date]
    )
  end
end
