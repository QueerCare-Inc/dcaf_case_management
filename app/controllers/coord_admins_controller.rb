# Create, edit, and update care_coordinators. The main care_coordinator view is edit.
class CoordAdminsController < ApplicationController
  include ActionController::Live
  before_action :confirm_admin_user, only: [:destroy]
  before_action :confirm_data_access, only: [:index]
  before_action :find_care_coordinator, if: :should_preload_care_coordinator_with_versions?
  rescue_from ActiveRecord::RecordNotFound,
              with: -> { redirect_to root_path }

  def index
    @coord_admins = CoordAdmin.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    coord_admin = CoordAdmin.new coord_admin_params

    if coord_admin.save
      flash[:notice] = t('flash.new_coord_admin_save')
      current_user.add_coord_admin coord_admin
    else
      flash[:alert] = t('flash.new_coord_admin_error', error: coord_admin.errors.full_messages.to_sentence)
    end

    redirect_to root_path
  end

  # TODO: consider if we want notes for care_coordinators as well as care recipients
  # def edit
  #   @note = @care_coordinator.notes.new
  # end

  def edit; end

  def update
    @coord_admin.last_edited_by = current_user

    respond_to do |format|
      format.js do
        respond_to_update_for_js_format
      end
      format.json do
        respond_to_update_for_json_format
      end
    end
  end

  # def data_entry
  #   @coord_admin = CoordAdmin.new
  # end

  # def data_entry_create
  #   @coord_admin = CoordAdmin.new coord_admin_params

  #   if @coord_admin.save
  #     flash[:notice] = t('flash.coord_admin_save_success',
  #                        coord_admin: @coord_admin.name,
  #                        org: current_tenant.name)
  #     redirect_to edit_coord_admin_path @coord_admin
  #   else
  #     flash[:alert] = t('flash.coord_admin_save_error', error: @coord_admin.errors.full_messages.to_sentence)
  #     render 'data_entry'
  #   end
  # end

  def destroy
    if @coord_admin.okay_to_destroy? && @coord_admin.destroy
      flash[:notice] = t('flash.coord_admin_removed_database')
      redirect_to authenticated_root_path
    else
      flash[:alert] = t('flash.coord_admin_removed_database_error')
      redirect_to edit_coord_admin_path(@coord_admin)
    end
  end

  private

  # preload coord_admin with versions for edit and js format update requests
  def should_preload_coord_admin_with_versions?
    action_name.to_sym == :edit || (action_name.to_sym == :update && !request.format.json?)
  end

  def find_coord_admin
    @coord_admin = CoordAdmin.includes(versions: [:item, :user])
                             .find params[:id]
  end

  def find_coord_admin_minimal
    @coord_admin = CoordAdmin.find params[:id]
  end

  # requests from our autosave using jquery ($(form).submit()) use the js format
  def respond_to_update_for_js_format
    if @coord_admin.update coord_admin_params
      @coord_admin = CoordAdmin.includes(versions: [:item, :user]).find(@coord_admin.id) # reload
      flash.now[:notice] = t('flash.coord_admin_info_saved', timestamp: Time.zone.now.display_timestamp)
    else
      error = @coord_admin.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end
  end

  # requests from our autosave using React (via the useFetch hook) use the json format
  def respond_to_update_for_json_format
    if @coord_admin.update coord_admin_params
      @coord_admin.reload
      render json: {
        coord_admin: @coord_admin.reload.as_json,
        flash: {
          notice: t('flash.coord_admin_info_saved', timestamp: Time.zone.now.display_timestamp)
        }
      }, status: :ok
    else
      render json: { flash: { alert: @coord_admin.errors.full_messages.to_sentence } },
             status: :unprocessable_entity
    end
  end

  COORD_ADMIN_BASIC_PARAMS = [
    :user_id, :region_id, :org_id
  ].freeze

  COORD_ADMIN_DASHBOARD_PARAMS = [
    :name, :primary_phone, :pronouns, :status
  ].freeze

  COORD_ADMIN_INFORMATION_PARAMS = [
    :age, :race_ethnicity, :language, :textable, :employment_status, :income,
    :city, :state, :zipcode,
    :emergency_contact, :emergency_contact_phone, :emergency_contact_relationship,
    :household_size_adults, :household_size_children,
    { special_circumstances: [] },
    { shifts: [] },
    { volunteer_types: [] },
    { patients: [] }
  ].freeze

  def coord_admin_params
    permitted_params = [].concat(
      COORD_ADMIN_BASIC_PARAMS, COORD_ADMIN_DASHBOARD_PARAMS, COORD_ADMIN_INFORMATION_PARAMS
    )
    # permitted_params.concat(FULFILLMENT_PARAMS) if current_user.allowed_data_access? #TODO: what do we want to include in data access mode
    params.require(:coord_admin).permit(permitted_params)
  end
end
