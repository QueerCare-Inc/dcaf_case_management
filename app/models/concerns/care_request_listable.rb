# Methods relating to management of a user's care_request list
module CareRequestListable
  extend ActiveSupport::Concern

  # Someone is recently called if:
  # someone has a call from the current_user
  # that is less than 8 hours old,
  # AND they would otherwise be in the care request list
  # (e.g. assigned to current region and in user.patients)
  def find_care_request_by_status(region, care_status)
    care_requests = ordered_care_requests(region)
    care_requests_by_status = care_requests.select { |x| x.care_status == care_status }
    care_requests_validated = care_requests.select { |x| x.validate_care_progress_status? }
    care_requests_by_status.select { |x| x.validate_care_progress_status? }
    # ordered_care_requests(region).select { |x| x.care_status == care_status && x.validate_care_progress_status? }
  end

  def care_coordinator_assigned_care_requests(region, current_user)
    # TODO: fix so that this points to the right care coordinator user
    care_coordinator = CareCoordinator.where(user_id: current_user.id)
    assigned_care_requests = find_care_request_by_status(region, :coordinator_assigned)
    assigned_care_requests.select(&:get_care_coordinator_id == care_coordinator.id)
  end

  def care_request_list(region)
    ordered_care_requests(region) # .reject { |x| recently_called_by_user? x }
  end

  # def recently_called_patients(region)
  #   ordered_patients(region).select { |x| recently_called_by_user? x }
  # end

  # def recently_reached_patients(region)
  #   ordered_patients(region).select { |x| recently_reached_by_user? x }
  # end

  def add_care_request(care_request)
    present_care_requests = care_request_list_entries.where(region: care_request.region).to_a
    return if present_care_requests.map { |x| x.care_request_id.to_s }.include? care_request.id.to_s

    # Increment existing care request list entries and then insert the new one.
    present_care_requests.each do |entry|
      entry.update order_key: entry.order_key + 1
    end
    care_request_list_entries.create! procedure: procedure,
                                      region: procedure.region,
                                      order_key: 0
    reload
  end

  def remove_care_request(care_request)
    care_request_list_entries.find_by!(procedure_id: procedure.id).destroy
    reload
  end

  def reorder_care_request_list(order, region)
    current_entries = care_request_list_entries.includes(:procedure, :org, :region, :user).where(region: region).to_a
    order.each_with_index do |pt, i|
      current = current_entries.find { |x| x.procedure_id.to_s == pt }
      current.update order_key: i
    end
    reload
  end

  # TIME_BEFORE_INACTIVE = 2.weeks

  # # # ToDo: create function to clear completed care
  # def clear_care_request_list(region)
  #   care_request_list_entries.where(region: region).destroy_all
  # end

  private

  def ordered_care_requests(region)
    # n+1 join here
    base_procedure = Procedure
    base_procedure.where(region: region)
                  .order(procedure_date: :asc)
                  #  .map(&:procedure)
                  .reject(&:nil?)
  end

  # def ordered_procedures(region)
  #   # n+1 join here
  #   # procedure_list_entries.includes(procedure: [:procedures, :fulfillment])
  #   procedure_list_entries.where(region: region)
  #                    .order(order_key: :asc)
  #                   #  .order(procedure_date: :asc)
  #                    .map(&:procedure)
  #                    .reject(&:nil?)
  # end

  # def recently_reached_by_user?(procedure)
  #   procedure.procedures.any? do |procedure|
  #     procedure.created_by_id == id && procedure.recent? && procedure.reached_procedure?
  #   end
  # end

  # def recently_called_by_user?(procedure)
  #   procedure.procedures.any? { |procedure| procedure.created_by_id == id && procedure.recent? }
  # end
end
