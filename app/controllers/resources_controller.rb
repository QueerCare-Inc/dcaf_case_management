# Resource-related functionality.
class ResourcesController < ApplicationController
  before_action :confirm_admin_user
  before_action :find_resource, only: [:update, :edit]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :bad_request }

  def index
    @resources = Resource.all.sort_by { |c| [c.name] }
    respond_to do |format|
      format.html
    end
  end

  def create
    @resource = Resource.new resource_params
    if @resource.save
      flash[:notice] = t('flash.resource_created', resource: @resource.name)
      redirect_to resources_path
    else
      flash[:alert] = t('flash.error_saving_resource', error: @resource.errors.full_messages.to_sentence)
      render 'new'
    end
  end

  def new
    @resource = Resource.new
  end

  def edit; end

  def update
    if @resource.update resource_params
      flash[:notice] = t('flash.resource_details_updated')
      redirect_to resources_path
    else
      flash[:alert] = t('flash.error_saving_resource_details', error: @resource.errors.full_messages.to_sentence)
      render 'edit'
    end
  end

  private

  def find_resource
    @resource = Resource.find params[:id]
  end

  def resource_params
    resource_params = [
      :website_link,
      :phone,
      :email,
      :contact_person,
      :services_provided,
      { regions: [] }
    ]

    params.require(:resource).permit(
      resource_params
    )
  end
end
