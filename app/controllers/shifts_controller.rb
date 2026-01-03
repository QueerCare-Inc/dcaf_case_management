# Shift-related functionality.
class ShiftsController < ApplicationController
  before_action :confirm_admin_user
  before_action :find_shift, only: [:update, :edit]
  before_action :find_procedure, only: [:new, :create]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :bad_request }

  def index
    @shifts = Shift.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    @shift = Shift.new(shift_params)
    @shift.procedure_id = @procedure.id

    if @shift.save
      flash[:notice] = t('flash.shift_created', shift: @shift.name)
      # redirect_to shifts_path
    else
      flash[:alert] = t('flash.error_saving_shift', error: @shift.errors.full_messages.to_sentence)
      # render 'new'
    end
  end

  def new
    # i18n-tasks-use t('activerecord.attributes.shift.phone_number')
    # i18n-tasks-use t('activerecord.attributes.shift.active')
    @shift = Shift.new
    @care_addresses = @procedure.care_addresses
  end

  def edit
    # @shift = Shift.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = t('flash.shift_not_found')
    # redirect_to root_path
  end

  def update
    if @shift.update shift_params
      flash[:notice] = t('flash.shift_details_updated')
      redirect_to shifts_path
    else
      flash[:alert] = t('flash.error_saving_shift_details', error: @shift.errors.full_messages.to_sentence)
      render 'edit'
    end
  end

  def show
    @shift = Shift.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = t('flash.shift_not_found')
    redirect_to root_path
  end

  private

  def find_procedure
    @procedure = Procedure.find(params[:procedure_id])
  end

  def find_shift
    @shift = Shift.find params[:id]
  end

  def shift_params
    shift_params = [
      :procedure_id,
      :shift_type,
      :start_time,
      :end_time,
      :care_address_id,
      { volunteers: [] },
      { services: [] }
    ]

    params.require(:shift).permit(
      shift_params
    )
  end
end
