# Single-serving controller for setting current region for a user.
class RegionsController < ApplicationController
  def new
    @regions = ActsAsTenant.current_tenant.regions.sort_by(&:name)
    raise Exceptions::NoRegionsForOrgError if @regions.count == 0

    if @regions.count == 1
      set_region_session @regions.first
      redirect_to authenticated_root_path
    end
    @regions
  end

  def create
    region = Region.find params[:region_id]
    session[:region_id] = region.id
    redirect_to authenticated_root_path
  end

  private

  def set_region_session(region)
    session[:region_id] = region.id
  end
end
