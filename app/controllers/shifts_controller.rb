class ShiftsController < ApplicationController
  before_action :find_patient, only: [:create]
  before_action :find_support, only: [:edit, :update, :destroy]
  rescue_from ActiveRecord::RecordNotFound,
              with: -> { head :not_found }

  def edit
    @note = @support.notes.new
    respond_to { |format| format.js }
  end

  def create
    @support = @patient.shifts.new shift_params
    if @support.save
      flash.now[:notice] = t('flash.patient_info_saved', timestamp: Time.zone.now.display_timestamp)
      @support = @patient.reload.shifts.order(created_at: :desc)
      respond_to { |format| format.js }
    else
      flash.now[:alert] = "Shift failed to save: #{@support.errors.full_messages.to_sentence}"
      respond_to do |format|
        format.js { render partial: 'layouts/flash_messages' }
      end
    end
  end

  def update
    if @support.update shift_params
      flash.now[:notice] = t('flash.patient_info_saved', timestamp: Time.zone.now.display_timestamp)
      respond_to { |format| format.js }
    else
      flash.now[:alert] = "Shift failed to save: #{@support.errors.full_messages.to_sentence}"
      respond_to do |format|
        format.js { render partial: 'layouts/flash_messages' }
      end
    end
  end

  def destroy
    flash.now[:alert] = 'Removed shift'
    @support.destroy
    respond_to { |format| format.js }
  end

  private

  # Only allow a list of trusted parameters through.
  def shift_params
    params.require(:shift)
          .permit(:name, :start_time, :end_time,
                  :confirmed, :support_type, :fullfilled)
  end

  def find_patient
    @patient = Patient.find params[:patient_id]
  end

  def find_support
    find_patient
    @support = @patient.shifts.find params[:id]
  end
end
