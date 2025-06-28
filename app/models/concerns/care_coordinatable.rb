# Methods relating to management of a adminstrative care coordinator's care list
module CareCoordinatable
  extend ActiveSupport::Concern

  # Someone is recently called if:
  # someone has a call from the current_user
  # that is less than 8 hours old,
  # AND they would otherwise be in the call list
  # (e.g. assigned to current region and in user.patients)

# ToDo: use current procedure statuses for all patients to populate

  def find_procedure_by_status(region, care_status)
    procedures = ordered_procedures(region)
    procedures_by_status = procedures.select { |x| x.care_status == care_status }
    procedures_validated = procedures.select { |x| x.validate_care_progress_status? }
    selected_procedures = procedures_by_status.select { |x| x.validate_care_progress_status? }
    # ordered_procedures(region).select { |x| x.care_status == care_status && x.validate_care_progress_status? }
    selected_procedures
  end

  def care_coordinator_assigned_procedures(region, current_user)
    care_cooredinator = Care_Coordinator.where(user_id: current_user.id)
    assigned_procedures = find_procedure_by_status(region, :coordinator_assigned)
    assigned_procedures.select(&:get_care_coordinator_id==care_cooredinator.id)
  end

  # def add_patient(patient)
  #   # present_calls = call_list_entries.where(region: patient.region).to_a
  #   base_patient = Patient
  #   current_patients = base_patient.where(region: patient.region).to_a
  #   return if current_patients.map { |x| x.patient_id.to_s }.include? patient.id.to_s

  #   # Increment existing patients and then insert the new one.
  #   current_patients.each do |entry|
  #     entry.update order_key: entry.order_key + 1
  #   end
  #   current_patients.create! patient: patient,
  #                            region: patient.region,
  #                            order_key: 0
  #   # ToDo: add and link Person to the patient

  #   reload
  # end

  # def remove_patient(patient)
  #   base_patient = Patient
  #   base_patient.find_by!(patient_id: patient.id).destroy
  #   reload
  # end

  # def reorder_patient_list(order, region)
  #   base_patient = Patient
  #   current_entries = base_patient.includes(:patient, :org, :region).where(region: region).to_a
  #   order.each_with_index do |pt, i|
  #     current = current_entries.find { |x| x.patient_id.to_s == pt }
  #     current.update order_key: i
  #   end
  #   reload
  # end

  # # # ToDo: create function to clear completed care
  # # def clean_patient_list_after_care_complete
  # #   ids_completed = recently_completed_patients(Region.all).map { |x| x.id.to_s}
  # #   active_patients.where(patient_id: ids_completed).mark_complete
  # #   reload
  # # end

  # private

  def ordered_procedures(region)
    # n+1 join here
    base_procedure = Procedure
    base_procedure.where(region: region)
                     .order(procedure_date: :asc)
                    #  .map(&:procedure)
                     .reject(&:nil?)
  end

  # # def recently_reached_by_user?(patient)
  # #   patient.calls.any? do |call|
  # #     call.created_by_id == id && call.recent? && call.reached_patient?
  # #   end
  # # end

  # # def recently_called_by_user?(patient)
  # #   patient.calls.any? { |call| call.created_by_id == id && call.recent? }
  # # end
end
