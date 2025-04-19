# Surgeon-related functionality.
class SurgeonsController < ApplicationController
  before_action :confirm_admin_user
  before_action :find_surgeon, only: [:update, :edit]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :bad_request }

  def index
    @surgeons = Surgeon.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    @surgeon = Surgeon.new surgeon_params
    if @surgeon.save
      flash[:notice] = t('flash.surgeon_created', surgeon: @surgeon.name)
      redirect_to surgeons_path
    else
      flash[:alert] = t('flash.error_saving_surgeon', error: @surgeon.errors.full_messages.to_sentence)
      render 'new'
    end
  end

  def new
    # i18n-tasks-use t('activerecord.attributes.surgeon.phone')
    # i18n-tasks-use t('activerecord.attributes.surgeon.active')
    @surgeon = Surgeon.new
  end

  def edit; end

  def update
    if @surgeon.update surgeon_params
      flash[:notice] = t('flash.surgeon_details_updated')
      redirect_to surgeons_path
    else
      flash[:alert] = t('flash.error_saving_surgeon_details', error: @surgeon.errors.full_messages.to_sentence)
      render 'edit'
    end
  end

  private

  def find_surgeon
    @surgeon = Surgeon.find params[:id]
  end

  def surgeon_params
    surgeon_params = [
      :region,
      :region_id,
      :name,
      :phone,
      :email,
      :active,
      { procedures: [] },
      { insurances: [] },
      { clinic_ids: [] }
    ]

    params.require(:surgeon).permit(
      surgeon_params
    )
  end
end
