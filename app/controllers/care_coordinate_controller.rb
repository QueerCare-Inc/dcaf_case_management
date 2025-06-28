# Controller for managing care coordination list.
class CareCoordinateController < ApplicationController
  include RegionsHelper

  before_action :retrieve_patients, only: [:add_patient, :remove_patient]
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }

  # def add_patient
  #   # ToDo: make sure that adding a patient also creates the associated Person
  #   current_user.add_patient @patient
  #   respond_to do |format|
  #     format.js { render template: 'users/refresh_care_requests', layout: false }
  #   end
  # end

  def remove_patient
    current_user.remove_patient @patient
    respond_to do |format|
      format.js { render template: 'users/refresh_care_requests', layout: false, locals: {care_status: 'archived'} }
      # ToDo: revisit this so that patients get properly deleted when necessary
    end
  end

  # def clear_current_user_call_list
  #   current_user.clear_call_list current_region
  #   respond_to do |format|
  #     format.js { render template: 'users/refresh_care_requests', layout: false }
  #   end
  # end

  def reorder_patient_list
    current_user.reorder_patient_list params[:order], current_region
    head :ok
  end

  private

  def retrieve_patients
    @patient = Patient.find params[:id]
  end
end
