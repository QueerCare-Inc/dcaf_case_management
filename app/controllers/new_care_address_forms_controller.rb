class NewCareAddressFormsController < ApplicationController
  def create
    Rails.logger.debug "Create action triggered for procedure_id: #{new_care_address_params[:procedure_id]}"
    @procedure = Procedure.find(new_care_address_params[:procedure_id])

    @care_address = NewCareAddressForm.new_form_from_procedure(@procedure)

    @care_address.assign_attributes(new_care_address_params)
    @care_address.phone_number = Phonelib.parse(@care_address.phone_number).e164

    if @care_address.save
      Rails.logger.debug "CareAddress saved successfully: #{@care_address.inspect}"
      respond_to do |format|
        format.js do
          render template: 'care_addresses/refresh_care_addresses',
                 layout: false
        end
      end
    else
      Rails.logger.debug "CareAddress Save Failed: #{@care_address.errors.full_messages}"
      Rails.logger.debug "New Care Address Params: #{new_care_address_params.inspect}"
      flash[:alert] = t('flash.error_saving_care_address', error: @care_address.errors.full_messages.to_sentence)
      respond_to do |format|
        format.js do
          render template: 'care_addresses/refresh_care_addresses',
                 layout: false
        end
      end
    end
    #   render :new
  end

  def new_care_address_params
    params.require(:new_care_address_form).permit(
      :region_id,
      :org_id,
      :patient_id,
      :procedure_id,
      :street_address,
      :city, :state,
      :zip,
      :closest_cross_street,
      :phone_number,
      :start_date,
      :end_date,
      :confirmed,
      :coordinates,
      :qc_house,
      { accessibility_options: [] }
    )
  end
end
