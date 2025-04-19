# Create, edit, and update care_coordinators. The main care_coordinator view is edit.
class CareCoordinatorsController < ApplicationController
  include ActionController::Live
  before_action :confirm_admin_user, only: [:destroy]
  before_action :confirm_data_access, only: [:index]
  before_action :find_care_coordinator, if: :should_preload_care_coordinator_with_versions?
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
    @care_coordinators = CareCoordinator.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    care_coordinator = CareCoordinator.new care_coordinator_params

    if care_coordinator.save
      flash[:notice] = t('flash.new_care_coordinator_save')
      current_user.add_care_coordinator care_coordinator
    else
      flash[:alert] = t('flash.new_care_coordinator_error', error: care_coordinator.errors.full_messages.to_sentence)
    end

    redirect_to root_path
  end

  # TODO: consider if we want notes for care_coordinators as well as care recipients
  # def edit
  #   @note = @care_coordinator.notes.new
  # end

  def edit; end

  def update
    @care_coordinator.last_edited_by = current_user

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
    @care_coordinator = CareCoordinator.new
  end

  def data_entry_create
    @care_coordinator = CareCoordinator.new care_coordinator_params

    if @care_coordinator.save
      flash[:notice] = t('flash.care_coordinator_save_success',
                         care_coordinator: @care_coordinator.name,
                         org: current_tenant.name)
      redirect_to edit_care_coordinator_path @care_coordinator
    else
      flash[:alert] = t('flash.care_coordinator_save_error', error: @care_coordinator.errors.full_messages.to_sentence)
      render 'data_entry'
    end
  end

  def destroy
    if @care_coordinator.okay_to_destroy? && @care_coordinator.destroy
      flash[:notice] = t('flash.care_coordinator_removed_database')
      redirect_to authenticated_root_path
    else
      flash[:alert] = t('flash.care_coordinator_removed_database_error')
      redirect_to edit_care_coordinator_path(@care_coordinator)
    end
  end

  private

  # preload care_coordinator with versions for edit and js format update requests
  def should_preload_care_coordinator_with_versions?
    action_name.to_sym == :edit || (action_name.to_sym == :update && !request.format.json?)
  end

  def find_care_coordinator
    @care_coordinator = CareCoordinator.includes(versions: [:item, :user])
                                       .find params[:id]
  end

  def find_care_coordinator_minimal
    @care_coordinator = CareCoordinator.find params[:id]
  end

  # requests from our autosave using jquery ($(form).submit()) use the js format
  def respond_to_update_for_js_format
    if @care_coordinator.update care_coordinator_params
      @care_coordinator = CareCoordinator.includes(versions: [:item, :user]).find(@care_coordinator.id) # reload
      flash.now[:notice] = t('flash.care_coordinator_info_saved', timestamp: Time.zone.now.display_timestamp)
    else
      error = @care_coordinator.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end
  end

  # requests from our autosave using React (via the useFetch hook) use the json format
  def respond_to_update_for_json_format
    if @care_coordinator.update care_coordinator_params
      @care_coordinator.reload
      render json: {
        care_coordinator: @care_coordinator.reload.as_json,
        flash: {
          notice: t('flash.care_coordinator_info_saved', timestamp: Time.zone.now.display_timestamp)
        }
      }, status: :ok
    else
      render json: { flash: { alert: @care_coordinator.errors.full_messages.to_sentence } },
             status: :unprocessable_entity
    end
  end

  CARE_COORDINATOR_DASHBOARD_PARAMS = [
    :name, :primary_phone, :pronouns, :status
  ].freeze

  CARE_COORDINATOR_INFORMATION_PARAMS = [
    :region_id, :user_id, :qc_housing_id,
    :age, :race_ethnicity, :language, :textable, :employment_status, :income,
    :city, :state, :zipcode,
    :emergency_contact, :emergency_contact_phone, :emergency_contact_relationship,
    :household_size_adults, :household_size_children,
    { special_circumstances: [] },
    { shifts: [] },
    { volunteer_types: [] },
    { patients: [] }
  ].freeze

  def care_coordinator_params
    permitted_params = [].concat(
      CARE_COORDINATOR_DASHBOARD_PARAMS, CARE_COORDINATOR_INFORMATION_PARAMS
    )
    # permitted_params.concat(FULFILLMENT_PARAMS) if current_user.allowed_data_access? #TODO: what do we want to include in data access mode
    params.require(:care_coordinator).permit(permitted_params)
  end
end
