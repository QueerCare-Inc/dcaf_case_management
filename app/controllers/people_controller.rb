# Create, edit, and update people. The main person view is edit.
class PeopleController < ApplicationController
  include ActionController::Live
  before_action :confirm_admin_user, only: [:destroy]
  before_action :confirm_data_access, only: [:index]
  before_action :find_person, if: :should_preload_person_with_versions?
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
    person = Person.new person_params

    if person.save
      flash[:notice] = t('flash.new_person_save')
      current_user.add_person person
    else
      flash[:alert] = t('flash.new_person_error', error: person.errors.full_messages.to_sentence)
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
    @note = @person.notes.new
  end

  def update
    @person.last_edited_by = current_user

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
  end

  def data_entry_create
    @person = Person.new person_params

    if @person.save
      flash[:notice] = t('flash.person_save_success',
                         person: @person.name,
                         org: current_tenant.name)
      redirect_to edit_person_path @person
    else
      flash[:alert] = t('flash.person_save_error', error: @person.errors.full_messages.to_sentence)
      render 'data_entry'
    end
  end

  def destroy
    if @person.okay_to_destroy? && @person.destroy
      flash[:notice] = t('flash.person_removed_database')
      redirect_to authenticated_root_path
    else
      flash[:alert] = t('flash.person_removed_database_error')
      redirect_to edit_person_path(@person)
    end
  end

  private

  # preload person with versions for edit and js format update requests
  def should_preload_person_with_versions?
    action_name.to_sym == :edit || (action_name.to_sym == :update && !request.format.json?)
  end

  def find_person
    @person = Person.includes(versions: [:item, :user])
                      .find params[:id]
  end

  def find_person_minimal
    @person = Person.find params[:id]
  end

  # requests from our autosave using jquery ($(form).submit()) use the js format
  def respond_to_update_for_js_format
    if @person.update person_params
      @person = Person.includes(versions: [:item, :user]).find(@person.id) # reload
      flash.now[:notice] = t('flash.person_info_saved', timestamp: Time.zone.now.display_timestamp)
    else
      error = @person.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end
  end

  # requests from our autosave using React (via the useFetch hook) use the json format
  def respond_to_update_for_json_format
    if @person.update person_params
      @person.reload
      render json: {
        person: @person.reload.as_json,
        flash: {
          notice: t('flash.person_info_saved', timestamp: Time.zone.now.display_timestamp)
        }
      }, status: :ok
    else
      render json: { flash: { alert: @person.errors.full_messages.to_sentence } }, status: :unprocessable_entity
    end
  end

  # PERSON_DASHBOARD_PARAMS = [
  #   :name, :care_coordinator,
  #   :procedure_date, :primary_phone, :pronouns, :status
  # ].freeze

  PERSON_INFORMATION_PARAMS = [
    :region_id,
    :age, :race_ethnicity, :language, :textable,
    :city, :state, :zipcode, 
    :emergency_contact, :emergency_contact_phone, :emergency_contact_relationship,
    :employment_status, :income,
    :household_size_adults, :household_size_children,
    { special_circumstances: [] }
  ].freeze

  # PROCEDURE_INFORMATION_PARAMS = [
  #   :clinic_id, :surgeon_id, :procedure_type, :appointment_time, :multiday_appointment
  # ].freeze

  # # Does this make sense for a one to many relationship?
  # PRACTICAL_SUPPORT_INFORMATION_PARAMS = [
  #   :practical_support_id, :street_address, :city, :state, :zipcode, :phone, :required_services
  # ]

  # FULFILLMENT_PARAMS = [
  #   fulfillment_attributes: [:id, :fulfilled, :procedure_date, :audited]
  # ].freeze

  # OTHER_PARAMS = [:shared_flag, :intake_date, :practical_support_waiver].freeze

  def person_params
    # permitted_params = [].concat(
    #   # PERSON_DASHBOARD_PARAMS, 
    #   PERSON_INFORMATION_PARAMS,
    #   # PROCEDURE_INFORMATION_PARAMS, OTHER_PARAMS
    # )
    # permitted_params.concat(FULFILLMENT_PARAMS) if current_user.allowed_data_access?
    params.require(:person).permit(PERSON_INFORMATION_PARAMS)
  end

  # def render_csv
  #   now = Time.zone.now.strftime('%Y%m%d')
  #   csv_filename = "person_data_export_#{now}.csv"
  #   set_headers

  #   response.status = 200

  #   send_stream(filename: "#{csv_filename}") do |y|
  #     Person.csv_header.each { |e| y.write e }
  #     Person.to_csv.each { |e| y.write e }
  #     ArchivedPerson.to_csv.each { |e| y.write e }
  #   end
  # end

  # def set_headers
  #   headers['Content-Type'] = 'text/csv'
  #   headers['X-Accel-Buffering'] = 'no'
  #   headers['Cache-Control'] = 'no-cache'
  #   headers[Rack::ETAG] = nil # Without this, data doesn't stream
  #   headers.delete('Content-Length')
  # end
end
