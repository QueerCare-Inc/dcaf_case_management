# Create, edit, and update patients. The main patient view is edit.
class PatientsController < ApplicationController
  include ActionController::Live
  before_action :confirm_admin_user, only: [:destroy]
  before_action :confirm_data_access, only: [:index]
  before_action :find_patient, if: :should_preload_patient_with_versions?
  rescue_from ActiveRecord::RecordNotFound,
              with: -> { redirect_to root_path }

  def index
    # n+1 join here
    respond_to do |format|
      format.csv do
        render_csv
      end
    end
  end

  def create
    person = Person.new
    patient = Patient.new patient_params, person_id: person.id
    patient.create_new_procedure

    if patient.save
      flash[:notice] = t('flash.new_patient_save')
      current_user.add_new_patient patient
    else
      flash[:alert] = t('flash.new_patient_error', error: patient.errors.full_messages.to_sentence)
    end

    redirect_to root_path
  end

  def edit
    # i18n-tasks-use t('activerecord.attributes.practical_support.confirmed')
    # i18n-tasks-use t('activerecord.attributes.practical_support.source')
    # i18n-tasks-use t('activerecord.attributes.practical_support.start_time')
    # i18n-tasks-use t('activerecord.attributes.practical_support.end_time')
    # i18n-tasks-use t('activerecord.attributes.practical_support.purchase_date')
    # i18n-tasks-use t('activerecord.attributes.practical_support.support_type')
    # i18n-tasks-use t('activerecord.attributes.fulfillment.audited')
    # i18n-tasks-use t('activerecord.attributes.fulfillment.fulfilled')
    # i18n-tasks-use t('activerecord.attributes.fulfillment.procedure_date')
    # i18n-tasks-use t('activerecord.attributes.practical_support.fulfilled')
    @note = @patient.notes.new
    @patient = Patient.find(params[:id])
    @procedure = @patient.get_current_procedure || @patient.create_new_procedure # Procedure.new
    @care_addresses = @procedure.care_addresses
    @care_request_entry = @procedure.care_request_entry
  end

  def update
    @patient.last_edited_by = current_user
    @procedure.last_edited_by = current_user if @procedure.present?

    respond_to do |format|
      format.js do
        respond_to_update_for_js_format
      end
      format.json do
        respond_to_update_for_json_format
      end
    end
  end

  def data_entry
    @person = Person.new
    @patient = Patient.new person_id: @person.id
  end

  def data_entry_create
    @person = Person.new
    @patient = Patient.new patient_params, person_id: @person.id

    if @patient.save
      flash[:notice] = t('flash.patient_save_success',
                         patient: @patient.name,
                         org: current_tenant.name)
      redirect_to edit_patient_path @patient
    else
      flash[:alert] = t('flash.patient_save_error', error: @patient.errors.full_messages.to_sentence)
      render 'data_entry'
    end
  end

  def destroy
    if @patient.okay_to_destroy? && @patient.destroy
      flash[:notice] = t('flash.patient_removed_database')
      redirect_to authenticated_root_path
    else
      flash[:alert] = t('flash.patient_removed_database_error')
      redirect_to edit_patient_path(@patient)
    end
  end

  def update_patient_and_person
    @person = Person.find(params[:patient][:person_id])
    @patient = Patient.find(params[:patient][:patient_id])

    patient_params = params[:patient].require(:patient).permit(PATIENT_INFORMATION_PARAMS)
    person_params = params[:patient].require(:person).permit(PERSON_INFORMATION_PARAMS)

    if @patient.update(patient_params) && @person.update(person_params)
      flash.now[:notice] = t('flash.patient_info_saved', timestamp: Time.zone.now.display_timestamp)
    else
      error = @patient.errors.full_messages.to_sentence
      flash.now[:alert] = error
      error = @person.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end
  end

  def update_user_patient_and_procedure
    @user = User.find(params[:patient][:user_id])
    @patient = Patient.find(params[:patient][:patient_id])
    @procedure = Procedure.find(params[:patient][:procedure_id])
    # debugger

    patient_params = params[:patient].require(:patient).permit(PATIENT_DASHBOARD_PARAMS)
    user_params = params[:patient].require(:user).permit(USER_DASHBOARD_PARAMS)
    procedure_params = params[:patient].require(:procedure).permit(PROCEDURE_DASHBOARD_PARAMS)

    if @patient.update(patient_params) && @user.update(user_params) && @procedure.update(procedure_params)
      flash.now[:notice] = t('flash.patient_info_saved', timestamp: Time.zone.now.display_timestamp)
    else
      error = @user.errors.full_messages.to_sentence
      flash.now[:alert] = error
      error = @patient.errors.full_messages.to_sentence
      flash.now[:alert] = error
      error = @procedure.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end
  end

  def assign_care_coordinator
    @patient = Patient.find(params[:patient_id])
    @care_coordinator = CareCoordinator.find(params[:care_coordinator_id])

    if @patient.update(care_coordinator: @care_coordinator)
      flash[:notice] = 'Care Coordinator assigned successfully.'
    else
      flash[:alert] = 'Failed to assign Care Coordinator.'
    end

    # redirect_to patient_path(@patient)
  end

  def remove_care_coordinator
    @patient = Patient.find(params[:patient_id])
    if @patient.update(care_coordinator: nil)
      flash[:notice] = 'Care Coordinator removed successfully.'
    else
      flash[:alert] = 'Failed to remove Care Coordinator.'
    end
  end

  private

  # preload patient with versions for edit and js format update requests
  def should_preload_patient_with_versions?
    Rails.logger.debug "Action Name: #{action_name}"
    Rails.logger.debug "Request Format: #{request.format}"
    action_name.to_sym == :edit || (action_name.to_sym == :update && !request.format.json?)
  end

  def find_patient
    Rails.logger.debug 'Inside find_patient before_action'
    Rails.logger.debug "Params: #{params.inspect}"
    @patient = Patient.includes(versions: [:item, :user])
                      .find params[:id]
  end

  def find_patient_minimal
    @patient = Patient.find params[:id]
  end

  # requests from our autosave using jquery ($(form).submit()) use the js format
  def respond_to_update_for_js_format
    @patient = Patient.find(@patient.id) # reload
    @procedure = @patient.get_current_procedure

    if @patient.update(patient_params) && @procedure.update(procedure_params)
      flash.now[:notice] = t('flash.patient_info_saved', timestamp: Time.zone.now.display_timestamp)
    else
      error = @patient.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end
  end

  # requests from our autosave using React (via the useFetch hook) use the json format
  def respond_to_update_for_json_format
    @patient = Patient.find(@patient.id) # reload
    @procedure = @patient.get_current_procedure

    if @patient.update(patient_params) && @procedure.update(procedure_params)
      @patient.reload
      render json: {
        patient: @patient.reload.as_json,
        flash: {
          notice: t('flash.patient_info_saved', timestamp: Time.zone.now.display_timestamp)
        }
      }, status: :ok
    else
      render json: { flash: { alert: @patient.errors.full_messages.to_sentence } }, status: :unprocessable_entity
    end
  end

  PATIENT_DASHBOARD_PARAMS = [
    :care_coordinator,
    :intake_date,
    { care_request_entry: [
      :care_coordinator_id
    ] }
    # :status
  ].freeze

  PATIENT_INFORMATION_PARAMS = [
    :region_id,
    :person_id,
    :legal_name,
    :insurance,
    :referred_by,
    :textable,
    :voicemail_preference,
    # :emergency_disclosure,
    # :advanced_care_directive,
    # :call_911_permissions,
    { in_case_of_emergency: [],
      special_circumstances: [] }
  ].freeze

  OTHER_PARAMS = [:shared_flag].freeze

  def patient_params
    permitted_params = [].concat(
      PATIENT_DASHBOARD_PARAMS,
      PATIENT_INFORMATION_PARAMS,
      OTHER_PARAMS
    )

    params.require(:patient).permit(permitted_params)
  end

  PERSON_INFORMATION_PARAMS = [
    :region_id,
    :age,
    :race_ethnicity,
    :language,
    :city, :state, :zipcode,
    :emergency_contact,
    :emergency_contact_phone,
    :emergency_contact_relationship,
    :employment_status,
    :income,
    :household_size_adults,
    :household_size_children,
    { emergency_contact_options: [] }
  ].freeze

  def person_params
    params.require(:person).permit(PERSON_INFORMATION_PARAMS)
  end

  PROCEDURE_DASHBOARD_PARAMS = [
    :procedure_date,
    :care_status
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

  USER_DASHBOARD_PARAMS = [
    :name,
    :pronouns,
    :primary_phone,
    :email
  ].freeze

  def render_csv
    now = Time.zone.now.strftime('%Y%m%d')
    csv_filename = "patient_data_export_#{now}.csv"
    set_headers

    response.status = 200

    send_stream(filename: "#{csv_filename}") do |y|
      Patient.csv_header.each { |e| y.write e }
      Patient.to_csv.each { |e| y.write e }
      ArchivedPatient.to_csv.each { |e| y.write e }
    end
  end

  def set_headers
    headers['Content-Type'] = 'text/csv'
    headers['X-Accel-Buffering'] = 'no'
    headers['Cache-Control'] = 'no-cache'
    headers[Rack::ETAG] = nil # Without this, data doesn't stream
    headers.delete('Content-Length')
  end
end
