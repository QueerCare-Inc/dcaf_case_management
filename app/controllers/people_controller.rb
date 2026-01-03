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
                         #  person: @person.name, #ToDo: revisit name for this flash notice
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

  PERSON_INFORMATION_PARAMS = [
    :region_id,
    :age, :race_ethnicity, :language,
    :city, :state, :zipcode,
    :emergency_contact, :emergency_contact_phone, :emergency_contact_relationship,
    :employment_status, :income,
    :household_size_adults, :household_size_children,
    { emergency_contact_options: [] }
  ].freeze

  def person_params
    params.require(:person).permit(PERSON_INFORMATION_PARAMS)
  end
end
