# Create, edit, and update volunteers. The main volunteer view is edit.
class VolunteersController < ApplicationController
  include ActionController::Live
  before_action :confirm_admin_user, only: [:destroy]
  before_action :confirm_data_access, only: [:index]
  before_action :find_volunteer, if: :should_preload_volunteer_with_versions?
  rescue_from ActiveRecord::RecordNotFound,
              with: -> { redirect_to root_path }

  # def index
  #   # n+1 join here
  #   respond_to do |format|
  #     format.csv do
  #       render_csv
  #     end
  #   end
  # end
  #
  def index
    @volunteers = Volunteer.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    volunteer = Volunteer.new volunteer_params

    if volunteer.save
      flash[:notice] = t('flash.new_volunteer_save')
      current_user.add_volunteer volunteer
    else
      flash[:alert] = t('flash.new_volunteer_error', error: volunteer.errors.full_messages.to_sentence)
    end

    redirect_to root_path
  end

  # TODO: consider if we want notes for volunteers as well as care recipients
  # def edit
  #   @note = @volunteer.notes.new
  # end

  def edit; end

  def update
    @volunteer.last_edited_by = current_user

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
    @volunteer = Volunteer.new
  end

  def data_entry_create
    @volunteer = Volunteer.new volunteer_params

    if @volunteer.save
      flash[:notice] = t('flash.volunteer_save_success',
                         volunteer: @volunteer.name,
                         org: current_tenant.name)
      redirect_to edit_volunteer_path @volunteer
    else
      flash[:alert] = t('flash.volunteer_save_error', error: @volunteer.errors.full_messages.to_sentence)
      render 'data_entry'
    end
  end

  def destroy
    if @volunteer.okay_to_destroy? && @volunteer.destroy
      flash[:notice] = t('flash.volunteer_removed_database')
      redirect_to authenticated_root_path
    else
      flash[:alert] = t('flash.volunteer_removed_database_error')
      redirect_to edit_volunteer_path(@volunteer)
    end
  end

  private

  # preload volunteer with versions for edit and js format update requests
  def should_preload_volunteer_with_versions?
    action_name.to_sym == :edit || (action_name.to_sym == :update && !request.format.json?)
  end

  def find_volunteer
    @volunteer = Volunteer.includes(versions: [:item, :user])
                          .find params[:id]
  end

  def find_volunteer_minimal
    @volunteer = Volunteer.find params[:id]
  end

  # requests from our autosave using jquery ($(form).submit()) use the js format
  def respond_to_update_for_js_format
    if @volunteer.update volunteer_params
      @volunteer = Volunteer.includes(versions: [:item, :user]).find(@volunteer.id) # reload
      flash.now[:notice] = t('flash.volunteer_info_saved', timestamp: Time.zone.now.display_timestamp)
    else
      error = @volunteer.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end
  end

  # requests from our autosave using React (via the useFetch hook) use the json format
  def respond_to_update_for_json_format
    if @volunteer.update volunteer_params
      @volunteer.reload
      render json: {
        volunteer: @volunteer.reload.as_json,
        flash: {
          notice: t('flash.volunteer_info_saved', timestamp: Time.zone.now.display_timestamp)
        }
      }, status: :ok
    else
      render json: { flash: { alert: @volunteer.errors.full_messages.to_sentence } }, status: :unprocessable_entity
    end
  end

  VOLUNTEER_DASHBOARD_PARAMS = [
    :name, :primary_phone, :pronouns, :status
  ].freeze

  VOLUNTEER_INFORMATION_PARAMS = [
    :region_id, :user_id, :qc_housing_id,
    :age, :race_ethnicity, :language, :textable, :employment_status, :income,
    :city, :state, :zipcode,
    :emergency_contact, :emergency_contact_phone, :emergency_contact_relationship,
    :household_size_adults, :household_size_children,
    { special_circumstances: [] },
    { shifts: [] },
    { volunteer_types: [] }
  ].freeze

  def volunteer_params
    permitted_params = [].concat(
      VOLUNTEER_DASHBOARD_PARAMS, VOLUNTEER_INFORMATION_PARAMS
    )
    # permitted_params.concat(FULFILLMENT_PARAMS) if current_user.allowed_data_access? #TODO: what do we want to include in data access mode
    params.require(:volunteer).permit(permitted_params)
  end
end
