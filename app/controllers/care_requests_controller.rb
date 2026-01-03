# class CareRequestsController < ApplicationController
#   def update_care_coordinator
#     care_request = CareRequest.find(params[:id])
#     if care_request.update(care_coordinator_id: params[:care_coordinator_id])
#       respond_to do |format|
#         format.js { render json: { success: true, message: 'Care Coordinator updated successfully' }, status: :ok }
#       end
#     else
#       respond_to do |format|
#         format.js do
#           render json: { success: false, message: 'Failed to update Care Coordinator' }, status: :unprocessable_entity
#         end
#       end
#     end
#   end

#   def mark_intake_complete
#     care_request = CareRequest.find(params[:id])
#     if care_request.update(intake_complete: true)
#       respond_to do |format|
#         format.js { render json: { success: true, message: 'Intake marked as complete' }, status: :ok }
#       end
#     else
#       respond_to do |format|
#         format.js do
#           render json: { success: false, message: 'Failed to mark intake as complete' }, status: :unprocessable_entity
#         end
#       end
#     end
#   end

#   def procedure_scheduled
#     care_request = CareRequest.find(params[:id])
#     if care_request.update(procedure_scheduled: true)
#       respond_to do |format|
#         format.js { render json: { success: true, message: 'Procedure marked as scheduled' }, status: :ok }
#       end
#     else
#       respond_to do |format|
#         format.js do
#           render json: { success: false, message: 'Failed to mark procedure as scheduled' },
#                  status: :unprocessable_entity
#         end
#       end
#     end
#   end

#   def procedure_confirmed
#     care_request = CareRequest.find(params[:id])
#     if care_request.update(procedure_confirmed: true)
#       respond_to do |format|
#         format.js { render json: { success: true, message: 'Procedure marked as confirmed' }, status: :ok }
#       end
#     else
#       respond_to do |format|
#         format.js do
#           render json: { success: false, message: 'Failed to mark procedure as confirmed' },
#                  status: :unprocessable_entity
#         end
#       end
#     end
#   end

#   def mark_under_care
#     care_request = CareRequest.find(params[:id])
#     if care_request.update(under_care: true)
#       respond_to do |format|
#         format.js { render json: { success: true, message: 'Patient marked as under care' }, status: :ok }
#       end
#     else
#       respond_to do |format|
#         format.js do
#           render json: { success: false, message: 'Failed to mark patient as under care' },
#                  status: :unprocessable_entity
#         end
#       end
#     end
#   end
# end
