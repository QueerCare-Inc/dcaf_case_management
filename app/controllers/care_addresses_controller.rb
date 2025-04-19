# Care Address-related functionality.
class CareAddressesController < ApplicationController
  before_action :confirm_admin_user
  before_action :find_care_address, only: [:update, :edit]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :bad_request }

  def index
    @care_addresses = CareAddress.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    @care_address = CareAddress.new care_address_params
    if @care_address.save
      flash[:notice] = t('flash.care_address_created', care_address: @care_address.name)
      redirect_to care_addresses_path
    else
      flash[:alert] = t('flash.error_saving_care_address', error: @care_address.errors.full_messages.to_sentence)
      render 'new'
    end
  end

  def new
    # i18n-tasks-use t('activerecord.attributes.care_address.phone')
    # i18n-tasks-use t('activerecord.attributes.care_address.active')
    @care_address = CareAddress.new
  end

  def edit; end

  def update
    if @care_address.update care_address_params
      flash[:notice] = t('flash.care_address_details_updated')
      redirect_to care_addresses_path
    else
      flash[:alert] =
        t('flash.error_saving_care_address_details', error: @care_address.errors.full_messages.to_sentence)
      render 'edit'
    end
  end

  private

  def find_care_address
    @care_address = CareAddress.find params[:id]
  end

  def care_address_params
    care_address_params = [
      :region,
      :region_id,
      :procedure_id,
      :patient_id,
      :street_address,
      :city,
      :state,
      :zip,
      :closest_cross_street,
      :phone,
      :start_date,
      :end_date,
      :confirmed,
      :coordinates,
      :qc_house
    ]

    params.require(:care_address).permit(
      care_address_params
    )
  end
end
