class ShiftEntriesController < ApplicationController
  before_action :confirm_admin_user
  before_action :find_shift_entry, only: [:update, :edit, :destroy]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :bad_request }

  def index
    @shift_entries = ShiftEntry.all.sort_by { |c| [c.shift.date, c.shift.start_time] }
    respond_to do |format|
      format.html
    end
  end

  def create
    @shift_entry = ShiftEntry.create_shift_entry(
      care_coordinator: CareCoordinator.find(params[:care_coordinator_id]),
      patient: Patient.find(params[:patient_id]),
      volunteer: Volunteer.find(params[:volunteer_id]),
      procedure: Procedure.find(params[:procedure_id]),
      care_address: CareAddress.find(params[:care_address_id]),
      shift: Shift.find(params[:shift_id])
    )

    if @shift_entry.persisted?
      flash[:notice] = t('flash.shift_entry_created')
      redirect_to shift_entries_path
    else
      flash[:alert] = t('flash.error_saving_shift_entry', error: @shift_entry.errors.full_messages.to_sentence)
      render 'new'
    end
  end

  def update
    @shift_entry = ShiftEntry.find(params[:id])

    if @shift_entry.update_shift_entry(shift_entry_params)
      flash[:notice] = 'Shift entry updated successfully.'
    else
      flash[:alert] = 'Failed to update shift entry.'
    end

    redirect_to shift_entries_path
  end

  def destroy
    @shift_entry = ShiftEntry.find(params[:id])

    if @shift_entry.remove_shift_entry
      flash[:notice] = 'Shift entry removed successfully.'
    else
      flash[:alert] = 'Failed to remove shift entry.'
    end

    redirect_to shift_entries_path
  end

  private

  def shift_entry_params
    params.require(:shift_entry).permit(:volunteer_id, :care_address_id)
  end
end
