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
    @patient = Patient.find(params[:patient_id])
    @procedure = @patient.create_new_procedure(procedure_params)

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

  def edit
    @procedure = Procedure.find(params[:procedure_id]) if params[:procedure_id]
    @care_address = @procedure.care_address || @procedure.create_new_care_address
    @note = Note.new

    respond_to do |format|
      format.js { render 'edit' } # Explicitly render edit.js.erb
      format.html { redirect_to procedures_path } # Optional fallback for HTML requests
    end
  end

  def update
    Rails.logger.debug "Params: #{params.inspect}"
    respond_to do |format|
      format.js do
        respond_to_update_for_js_format
      end
      format.json do
        respond_to_update_for_json_format
      end
    end

    # if @procedure.update procedure_params
    #   flash[:notice] = t('flash.procedure_details_updated')
    #   redirect_to procedures_path
    # else
    #   flash[:alert] = t('flash.error_saving_procedure_details', error: @procedure.errors.full_messages.to_sentence)
    #   render 'edit'
    # end
  end

  # def add_address
  #   # debugger
  #   @procedure = Procedure.find(params[:id])
  #   @care_address = @procedure.create_new_care_address # care_addresses.build(care_address_params)
  # end

  def add_care_address
    Rails.logger.debug "Params: #{params.inspect}"

    @procedure = Procedure.find(params[:id])
    @new_care_address_form = NewCareAddressForm.new

    # Ensure a CareAddress object exists for the form
    # @care_address = @procedure.care_addresses.build
    @care_address = @procedure.create_new_care_address
    Rails.logger.debug "CareAddress: #{@care_address.inspect}"
    if params[:new_care_address_form]
      for k, v in params[:new_care_address_form]
        @care_address.send("#{k}=", v) if @care_address.respond_to?("#{k}=")
      end
    end

    if @care_address.save
      flash.now[:notice] = t('flash.care_address_added', timestamp: Time.zone.now.display_timestamp)
      respond_to do |format|
        format.js { render 'care_addresses/refresh_care_addresses' }
      end
    else
      Rails.logger.debug "CareAddress Errors: #{@care_address.errors.full_messages}"
      respond_to do |format|
        format.js { render 'care_addresses/new_care_address' } # Render JavaScript to show the new care address form
      end
    end
  end

  def search_care_address
    @procedure = Procedure.find(params[:id])
    # @care_address_results = @procedure.care_address_list(@procedure).where('street_address ILIKE ?',
    #                                                                        "%#{params[:search]}%")
    @care_address_results = @procedure.care_address_list(@procedure).select do |care_address|
      care_address.street_address.downcase.include?(params[:search].downcase)
    end
    @new_care_address_form = NewCareAddressForm.new

    respond_to do |format|
      format.js { render 'care_addresses/care_address_search' }
    end
  end

  # def care_addresses # add_care_address
  #   @procedure = Procedure.find(params[:id])
  #   @new_care_address_form = NewCareAddressForm.new

  #   # Ensure a CareAddress object exists for the form
  #   # @care_address = @procedure.care_addresses.build
  #   @care_address = @procedure.create_new_care_address
  #   @care_address.update(care_address_params) if params[:care_address]
  #   debugger
  #   if @care_address.save
  #     flash.now[:notice] = t('flash.care_address_added', timestamp: Time.zone.now.display_timestamp)
  #     respond_to do |format|
  #       format.js { render 'care_addresses/refresh_care_addresses' }
  #     end
  #   else
  #     respond_to do |format|
  #       format.js { render 'care_addresses/new_care_address' } # Render JavaScript to show the new care address form
  #     end
  #   end
  # end

  def update_practical_support
    @procedure = Procedure.find(params[:procedure][:procedure_id])
    procedure_params = params[:procedure].require(:procedure).permit(PROCEDURE_PRACTICAL_SUPPORT_PARAMS)
    if @procedure.update(procedure_params)
      flash.now[:notice] = t('flash.practical_support_info_saved', timestamp: Time.zone.now.display_timestamp)
    else
      error = @procedure.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end
  end

  def generate_shifts
    # TODO: add completion bar or spinner
    @procedure = Procedure.find(params[:id])

    if @procedure.generate_shifts # Call the method to generate shifts
      flash.now[:notice] = t('flash.procedure_info_saved', timestamp: Time.zone.now.display_timestamp)

      respond_to do |format|
        format.js { render template: 'shifts/refresh_shifts', layout: false }
      end
    else
      error = @procedure.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end
  end

  def select_care_address
    @procedure = Procedure.find(params[:id])
    @care_addresses = @procedure.care_addresses.distinct

    # Prepare variables for rendering the new shift form
    @care_address_id = params[:care_address_id]
    @new_shift_form = NewShiftForm.new(care_address_id: @care_address_id)
    @shift = Shift.new # Ensure @shift is initialized

    respond_to do |format|
      format.js { render 'shifts/shift_add' }
    end
  end

  def build_shift(care_address, shift_form_params)
    shift = @procedure.create_new_shift(care_address.id)
    for k, v in shift_form_params[:shift]
      shift.send("#{k}=", v) if shift.respond_to?("#{k}=")
    end
    shift
  end

  def build_shift_entry(care_address, shift)
    ShiftEntry.new(
      org_id: @procedure.org_id,
      region_id: @procedure.region_id,
      care_coordinator_id: @procedure.patient.care_coordinator_id,
      care_address_id: care_address.id,
      procedure_id: @procedure.id,
      patient_id: @procedure.patient.id,
      volunteer_id: nil,
      # volunteer: current_user, # Assuming the current user is the volunteer
      shift_id: shift.id
    )
  end

  def add_shift
    Rails.logger.debug "Params: #{params.inspect}"

    @procedure = Procedure.find(params[:id])
    @care_address = @procedure.care_addresses.find_by(id: params[:new_shift_form][:care_address_id])

    unless @care_address
      flash.now[:alert] = t('flash.error_care_address_not_found')
      respond_to do |format|
        format.js { render 'shifts/new_shift' }
      end
      return
    end

    @new_shift_form = NewShiftForm.new
    @shift = build_shift(@care_address, params[:new_shift_form])
    if @shift.save
      @shift_entry = build_shift_entry(@care_address, @shift)

      if @shift_entry.save
        flash.now[:notice] = t('flash.shift_added', timestamp: Time.zone.now.display_timestamp)
        respond_to do |format|
          format.js { render 'shifts/refresh_shifts' }
        end
      else
        Rails.logger.debug "ShiftEntry Errors: #{@shift_entry.errors.full_messages}"
        respond_to do |format|
          format.js { render 'shifts/new_shift' }
        end
      end
    else
      Rails.logger.debug "Shift Errors: #{@shift.errors.full_messages}"
      respond_to do |format|
        format.js { render 'shifts/new_shift' }
      end
    end
  end

  def week
    @date = params[:date].to_date
    @shifts = Shift.where(start_time: @date.beginning_of_week..@date.end_of_week)

    render partial: 'simple_calendar/week_calendar', locals: { calendar: SimpleCalendar::WeekCalendar.new(@date), date_range: @date.beginning_of_week..@date.end_of_week, passed_block: lambda { |day, events|
      render_shifts(day, events)
    } }
  end

  private

  def render_shifts(day, events)
    events.each do |event|
      concat(content_tag(:div,
                         "#{event.shift_type}: #{event.start_time.strftime('%I:%M %p')} - #{event.end_time.strftime('%I:%M %p')}"))
    end
  end

  def find_procedure
    @procedure = Procedure.find params[:id]
  end

  PROCEDURE_PRACTICAL_SUPPORT_PARAMS = [
    :service_start,
    :intensive_service_end,
    :service_end,
    { services: [] }
  ].freeze

  def procedure_params
    procedure_params = [
      :region,
      :region_id,
      :patient_id,
      :surgeon_id,
      :clinic_id,
      :procedure_date,
      :procedure_type,
      :service_start,
      :intensive_service_end,
      :service_end,
      :care_status,
      :intake_date,
      { services: [] }
    ]

    params.require(:procedure).permit(
      procedure_params
    )
  end

  def new_care_address_params
    params.require(:new_care_address_form).permit(
      :street_address,
      :city,
      :state,
      :zip,
      :phone_number,
      :qc_house,
      :start_date,
      :end_date,
      :confirmed,
      accessibility_options: []
    )
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

  # requests from our autosave using jquery ($(form).submit()) use the js format
  def respond_to_update_for_js_format
    if @procedure.update procedure_params
      @procedure = Procedure.find(@procedure.id) # reload
      flash.now[:notice] = t('flash.procedure_details_updated', timestamp: Time.zone.now.display_timestamp)

      # # Render the updated clinic information
      # render partial: 'procedures/clinic_information', locals: { clinic: @procedure.get_clinic }

      # redirect_to procedures_path
    else
      error = @procedure.errors.full_messages.to_sentence
      flash.now[:alert] = error
      render 'edit'
    end
  end

  # # requests from our autosave using React (via the useFetch hook) use the json format
  def respond_to_update_for_json_format
    if @procedure.update procedure_params
      # @procedure.reload
      @procedure = Procedure.find(@procedure.id) # reload
      render json: {
        procedure: @procedure.reload.as_json,
        flash: {
          notice: t('flash.procedure_details_updated', timestamp: Time.zone.now.display_timestamp)
        }
      }, status: :ok
    else
      render json: { flash: { alert: @procedure.errors.full_messages.to_sentence } }, status: :unprocessable_entity
      # render 'edit'
    end
  end
end
