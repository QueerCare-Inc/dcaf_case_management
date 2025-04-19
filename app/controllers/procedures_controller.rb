# Procedure-related functionality.
class ProceduresController < ApplicationController
  before_action :confirm_admin_user
  before_action :find_procedure, only: [:update, :edit]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :bad_request }

  def index
    @procedures = Procedure.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    @procedure = Procedure.new procedure_params
    if @procedure.save
      flash[:notice] = t('flash.procedure_created', procedure: @procedure.name)
      redirect_to procedures_path
    else
      flash[:alert] = t('flash.error_saving_procedure', error: @procedure.errors.full_messages.to_sentence)
      render 'new'
    end
  end

  def new
    # i18n-tasks-use t('activerecord.attributes.procedure.phone')
    # i18n-tasks-use t('activerecord.attributes.procedure.active')
    @procedure = Procedure.new
  end

  def edit; end

  def update
    if @procedure.update procedure_params
      flash[:notice] = t('flash.procedure_details_updated')
      redirect_to procedures_path
    else
      flash[:alert] = t('flash.error_saving_procedure_details', error: @procedure.errors.full_messages.to_sentence)
      render 'edit'
    end
  end

  private

  def find_procedure
    @procedure = Procedure.find params[:id]
  end

  def procedure_params
    procedure_params = [
      :region,
      :region_id,
      :patient_id,
      :surgeon_id,
      :clinic_id,
      :procedure_date,
      :type,
      :service_start,
      :intensive_service_end,
      :service_end,
      :status,
      { services: [] },
      { care_addresses: [] },
      { shifts: [] },
      { reimbursements: [] }
    ]

    params.require(:procedure).permit(
      procedure_params
    )
  end
end
