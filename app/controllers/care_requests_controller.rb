class CareRequestsController < ApplicationController
  # before_action :find_patient, only: [:create, :destroy]

  # def create
  #   debugger
  #   @procedure = @patient.create_new_procedure 
  # rescue ArgumentError
  #   head :bad_request
  # end

  # def new
  #   debugger
  #   @patient = Patient.find params[:patient_id]
  #   respond_to do |format|
  #     format.js
  #   end
  # end

  # # def destroy
  # #   call = @patient.calls.find params[:id]
  # #   if call.created_by != current_user || !call.recent?
  # #     head :forbidden
  # #   elsif call.destroy
  # #     respond_to { |format| format.js }
  # #   else
  # #     head :bad_request
  # #   end
  # # end

  # private

  # # def care_request_params
  # #   params.require(:procedure).permit(:status)
  # # end

  # def find_patient
  #   @patient = Patient.find params[:patient_id]
  # end

  # # def call_saved_and_patient_reached(call, params)
  # #   call.save && params[:call][:status] == 'reached_patient'
  # # end
end