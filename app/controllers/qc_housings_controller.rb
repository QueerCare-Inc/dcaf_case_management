# QC Housing-related functionality.
class QcHousingsController < ApplicationController
  before_action :confirm_admin_user
  before_action :find_qc_housing, only: [:update, :edit]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :bad_request }

  def index
    @qc_housings = QcHousing.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    @qc_housing = QcHousing.new qc_housing_params
    if @qc_housing.save
      flash[:notice] = t('flash.qc_housing_created', qc_housing: @qc_housing.name)
      redirect_to qc_housings_path
    else
      flash[:alert] = t('flash.error_saving_qc_housing', error: @qc_housing.errors.full_messages.to_sentence)
      render 'new'
    end
  end

  def new
    # i18n-tasks-use t('activerecord.attributes.qc_housing.phone')
    # i18n-tasks-use t('activerecord.attributes.qc_housing.active')
    @qc_housing = QcHousing.new
  end

  def edit; end

  def update
    if @qc_housing.update qc_housing_params
      flash[:notice] = t('flash.qc_housing_details_updated')
      redirect_to qc_housings_path
    else
      flash[:alert] = t('flash.error_saving_qc_housing_details', error: @qc_housing.errors.full_messages.to_sentence)
      render 'edit'
    end
  end

  private

  def find_qc_housing
    @qc_housing = QcHousing.find params[:id]
  end

  def qc_housing_params
    qc_housing_params = [
      :region,
      :region_id,
      :volunteer_id,
      :street_address,
      :city,
      :state,
      :closest_cross_street,
      :zip,
      :phone,
      :accessability,
      { availabilities: [] },
      { care_addresses: [] }
    ]

    params.require(:qc_housing).permit(
      qc_housing_params
    )
  end
end
