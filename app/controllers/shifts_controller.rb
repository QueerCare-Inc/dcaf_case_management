# Shift-related functionality.
class ShiftsController < ApplicationController
  before_action :confirm_admin_user
  before_action :find_shift, only: [:update, :edit]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :bad_request }

  def index
    @shifts = Shift.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    @shift = Shift.new shift_params
    if @shift.save
      flash[:notice] = t('flash.shift_created', shift: @shift.name)
      redirect_to shifts_path
    else
      flash[:alert] = t('flash.error_saving_shift', error: @shift.errors.full_messages.to_sentence)
      render 'new'
    end
  end

  def new
    # i18n-tasks-use t('activerecord.attributes.shift.phone')
    # i18n-tasks-use t('activerecord.attributes.shift.active')
    @shift = Shift.new
  end

  def edit; end

  def update
    if @shift.update shift_params
      flash[:notice] = t('flash.shift_details_updated')
      redirect_to shifts_path
    else
      flash[:alert] = t('flash.error_saving_shift_details', error: @shift.errors.full_messages.to_sentence)
      render 'edit'
    end
  end

  private

  def find_shift
    @shift = Shift.find params[:id]
  end

  def shift_params
    shift_params = [
      :region,
      :region_id,
      :procedure_id,
      :patient_id,
      :type,
      :start_time,
      :end_time,
      { volunteers: [] },
      { care_addresses: [] },
      { services: [] }
    ]

    params.require(:shift).permit(
      shift_params
    )
  end
end
