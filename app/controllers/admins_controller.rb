# Create, edit, and update care_coordinators. The main care_coordinator view is edit.
class AdminsController < ApplicationController
  include ActionController::Live
  before_action :confirm_admin_user, only: [:destroy]
  before_action :confirm_data_access, only: [:index]
  before_action :find_admin, if: :should_preload_admin_with_versions?
  rescue_from ActiveRecord::RecordNotFound,
              with: -> { redirect_to root_path }

  def index
    @admins = Admin.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    admin = Admin.new admin_params

    if admin.save
      flash[:notice] = t('flash.new_admin_save')
      current_user.add_admin admin
    else
      flash[:alert] = t('flash.new_admin_error', error: admin.errors.full_messages.to_sentence)
    end

    redirect_to root_path
  end

  # TODO: consider if we want notes for care_coordinators as well as care recipients
  # def edit
  #   @note = @care_coordinator.notes.new
  # end

  def edit; end

  def update
    @admin.last_edited_by = current_user

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
  #   @admin = Admin.new
  # end

  # def data_entry_create
  #   @admin = Admin.new admin_params

  #   if @admin.save
  #     flash[:notice] = t('flash.admin_save_success',
  #                        admin: @admin.name,
  #                        org: current_tenant.name)
  #     redirect_to edit_admin_path @admin
  #   else
  #     flash[:alert] = t('flash.admin_save_error', error: @admin.errors.full_messages.to_sentence)
  #     render 'data_entry'
  #   end
  # end

  def destroy
    if @admin.okay_to_destroy? && @admin.destroy
      flash[:notice] = t('flash.admin_removed_database')
      redirect_to authenticated_root_path
    else
      flash[:alert] = t('flash.admin_removed_database_error')
      redirect_to edit_admin_path(@admin)
    end
  end

  private

  # preload admin with versions for edit and js format update requests
  def should_preload_admin_with_versions?
    action_name.to_sym == :edit || (action_name.to_sym == :update && !request.format.json?)
  end

  def find_admin
    @admin = Admin.includes(versions: [:item, :user])
                  .find params[:id]
  end

  def find_admin_minimal
    @admin = Admin.find params[:id]
  end

  # requests from our autosave using jquery ($(form).submit()) use the js format
  def respond_to_update_for_js_format
    if @admin.update admin_params
      @admin = Admin.includes(versions: [:item, :user]).find(@admin.id) # reload
      flash.now[:notice] = t('flash.admin_info_saved', timestamp: Time.zone.now.display_timestamp)
    else
      error = @admin.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end
  end

  # requests from our autosave using React (via the useFetch hook) use the json format
  def respond_to_update_for_json_format
    if @admin.update admin_params
      @admin.reload
      render json: {
        admin: @admin.reload.as_json,
        flash: {
          notice: t('flash.admin_info_saved', timestamp: Time.zone.now.display_timestamp)
        }
      }, status: :ok
    else
      render json: { flash: { alert: @admin.errors.full_messages.to_sentence } },
             status: :unprocessable_entity
    end
  end

  ADMIN_BASIC_PARAMS = [
    :user_id, :region_id, :org_id
  ].freeze

  ADMIN_DASHBOARD_PARAMS = [
    :name, :primary_phone, :pronouns, :status
  ].freeze

  ADMIN_INFORMATION_PARAMS = [
    :age, :race_ethnicity, :language, :textable, :employment_status, :income,
    :city, :state, :zipcode,
    :emergency_contact, :emergency_contact_phone, :emergency_contact_relationship,
    :household_size_adults, :household_size_children,
    { special_circumstances: [] },
    { shifts: [] },
    { volunteer_types: [] },
    { patients: [] }
  ].freeze

  def admin_params
    permitted_params = [].concat(
      ADMIN_BASIC_PARAMS, ADMIN_DASHBOARD_PARAMS, ADMIN_INFORMATION_PARAMS
    )
    # permitted_params.concat(FULFILLMENT_PARAMS) if current_user.allowed_data_access? #TODO: what do we want to include in data access mode
    params.require(:admin).permit(permitted_params)
  end
end
