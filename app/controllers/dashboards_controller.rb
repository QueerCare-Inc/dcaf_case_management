# Controller for rendering the home view and patient search.
class DashboardsController < ApplicationController
  include RegionsHelper

  before_action :pick_region_if_not_set, only: [:index, :search]

  def index
    @shared_patients = eager_loaded_patients.shared_patients(current_region)
    # @unconfirmed_support_patients = eager_loaded_patients.unconfirmed_practical_support(current_region)
  end

  def search
    @results = if params[:search].present?
                 eager_loaded_patients.search params[:search],
                                              regions: [current_region || Region.all]
               else
                 []
               end

    @patient = Patient.new
    @today = Time.zone.today.to_date
    @phone = searched_for_phone?(params[:search]) ? params[:search] : ''
    @name = searched_for_name?(params[:search]) ? params[:search] : ''

    respond_to { |format| format.js }
  end

  private

  def eager_loaded_patients
    Patient.includes([:calls, :fulfillment])
  end

  def searched_for_phone?(query)
    !/[a-z]/i.match query
  end

  def searched_for_name?(query)
    /[a-z]/i.match query
  end

  def pick_region_if_not_set
    redirect_to new_region_path if session[:region_id].blank?
  end
end
