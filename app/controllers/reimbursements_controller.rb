# Reimbursement-related functionality.
class ReimbursementsController < ApplicationController
  before_action :confirm_admin_user
  before_action :find_reimbursement, only: [:update, :edit]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :bad_request }

  def index
    @reimbursements = Reimbursement.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    @reimbursement = Reimbursement.new reimbursement_params
    if @reimbursement.save
      flash[:notice] = t('flash.reimbursement_created', reimbursement: @reimbursement.name)
      redirect_to reimbursements_path
    else
      flash[:alert] = t('flash.error_saving_reimbursement', error: @reimbursement.errors.full_messages.to_sentence)
      render 'new'
    end
  end

  def new
    # i18n-tasks-use t('activerecord.attributes.reimbursement.phone')
    # i18n-tasks-use t('activerecord.attributes.reimbursement.active')
    @reimbursement = Reimbursement.new
  end

  def edit; end

  def update
    if @reimbursement.update reimbursement_params
      flash[:notice] = t('flash.reimbursement_details_updated')
      redirect_to reimbursements_path
    else
      flash[:alert] =
        t('flash.error_saving_reimbursement_details', error: @reimbursement.errors.full_messages.to_sentence)
      render 'edit'
    end
  end

  private

  def find_reimbursement
    @reimbursement = Reimbursement.find params[:id]
  end

  def reimbursement_params
    reimbursement_params = [
      :region,
      :region_id,
      :patient_id,
      :procedure_id,
      :date,
      :type,
      :amount,
      :status
    ]

    params.require(:reimbursement).permit(
      reimbursement_params
    )
  end
end
