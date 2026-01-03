# Controller for rendering the practical support view and patient search.
class PracticalSupportsController < ApplicationController
  include RegionsHelper

  before_action :pick_region_if_not_set, only: [:index, :search]

  def index
    # @shared_patients = eager_loaded_patients.shared_patients(current_region)
    # @unconfirmed_support_patients = eager_loaded_patients.unconfirmed_practical_support(current_region)
  end

  def search
    @procedure_results = if params[:search].present?
                 eager_loaded_procedures.search params[:search],
                                              regions: [current_region || Region.all]
               else
                 []
               end
    
    @patient = Patient.find(params[:patient_id]) if params[:patient_id]

    @procedure = Procedure.new

    @care_address_results = if params[:search].present?
                eager_loaded_care_addresses.search params[:search],
                                             regions: [current_region || Region.all]
              else
                []
              end

    @care_address = CareAddress.new
    # @today = Time.zone.today.to_date
    # @phone_number = searched_for_phone?(params[:search]) ? params[:search] : ''
    
    @new_care_address_form = NewCareAddressForm.new
    
    respond_to { |format| format.js }
  end

  private

  def eager_loaded_procedures
    Procedure.includes(:patient)
  end 

  def eager_loaded_care_addresses
    CareAddress.includes(:procedure)
  end

  def searched_for_phone?(query)
    !/[a-z]/i.match query
  end

  def pick_region_if_not_set
    redirect_to new_region_path if session[:region_id].blank?
  end
end
