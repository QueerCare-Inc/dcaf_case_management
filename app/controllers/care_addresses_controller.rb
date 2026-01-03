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

  # def create
  #   @care_address = CareAddress.new care_address_params
  #   if @care_address.save
  #     flash[:notice] = t('flash.care_address_created', care_address: @care_address.name)
  #     redirect_to care_addresses_path
  #   else
  #     flash[:alert] = t('flash.error_saving_care_address', error: @care_address.errors.full_messages.to_sentence)
  #     render 'new'
  #   end
  # end

  def create
    @procedure = Procedure.find_by(id: params[:procedure_id])
    unless @procedure
      flash[:alert] = t('flash.error_procedure_not_found')
      redirect_back fallback_location: 'practical-support-patient-form'
    end

    @care_address = @procedure.care_addresses.build(care_address_params)

    if @care_address.save
      flash[:notice] = t('flash.care_address_details_updated')
      respond_to do |format|
        format.js { render 'care_addresses/create.js.erb' } # create.js.erb to append row and clear form
      end
    else
      flash[:alert] =
        t('flash.error_saving_care_address_details', error: @care_address.errors.full_messages.to_sentence)
      redirect_back fallback_location: 'practical-support-patient-form'
    end
  end

  def new
    # i18n-tasks-use t('activerecord.attributes.care_address.phone_number')
    # i18n-tasks-use t('activerecord.attributes.care_address.active')
    # @care_address = CareAddress.new
    @procedure = Procedure.find(params[:procedure_id])
    @care_address = @procedure.create_new_care_address
  end

  # def edit
  #   if @care_address.save
  #     flash[:notice] = t('flash.care_address_details_updated')
  #     respond_to do |format|
  #       format.js { render 'care_addresses/create.js.erb' } # create.js.erb to append row and clear form
  #     end
  #   else
  #     flash[:alert] =
  #       t('flash.error_saving_care_address_details', error: @care_address.errors.full_messages.to_sentence)
  #   end
  # end
  def edit
    # @shift = Shift.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = t('flash.care_address_not_found')
    # redirect_to root_path
  end

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

  # def save
  #   debugger
  #   @procedure = Procedure.find(params[:procedure_id])
  #   @care_address = @procedure.create_new_care_address

  #   if :procedure in params
  #     street_address = params[:procedure][:street_address]
  #     city = params[:procedure][:city]
  #     state = params[:procedure][:state]
  #     zip = params[:procedure][:zip]
  #     phone_number = params[:procedure][:phone_number]
  #     # if :accessibility_options in params[:procedure]
  #     #   accessibility_options = params[:procedure][:accessibility_options]
  #     # elsif :accessibility_options in params[:care_address]
  #     #   accessibility_options = params[:care_address][:accessibility_options]
  #     # end
  #   else
  #     street_address = params[:street_address]
  #     city = params[:city]
  #     state = params[:state]
  #     zip = params[:zip]
  #     phone_number = params[:phone_number]
  #     accessibility_options = params[:accessibility_options]
  #   end

  #   @care_address = @care_address.update street_address: street_address,
  #                                        city: city,
  #                                        state: state,
  #                                        zip: zip,
  #                                        phone_number: phone_number,
  #                                        accessibility_options: accessibility_options
  # end

  def destroy
    @care_address = CareAddress.find(params[:id])
    Rails.logger.debug "Deleting CareAddress: #{@care_address.id}"
    @care_address.destroy
    flash[:notice] = t('flash.care_address_deleted', care_address: @care_address.street_address)
  rescue StandardError => e
    Rails.logger.error "Error deleting CareAddress: #{e.message}"
    raise
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
      :phone_number,
      :start_date,
      :end_date,
      :confirmed,
      :coordinates,
      :qc_house,
      { accessibility_options: [] }
    ]

    params.require(:care_address).permit(
      care_address_params
    )
  end
end
