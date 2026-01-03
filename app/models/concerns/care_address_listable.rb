# Methods relating to management of a procedure's care_address list
module CareAddressListable
  extend ActiveSupport::Concern

  def care_address_list(procedure)
    ordered_care_addresses(procedure)
  end

  def add_care_address(care_address)
    present_care_addresses = care_address_list_entries.where(procedure_id: care_address.procedure_id).to_a
    return if present_care_addresses.map { |x| x.care_address_id.to_s }.include? care_address.id.to_s

    # Increment existing care request list entries and then insert the new one.
    present_care_addresses.each do |entry|
      entry.update order_key: entry.order_key + 1
    end
    care_address_list_entries.create! care_address_id: care_address.id,
                                      procedure_id: care_address.procedure_id,
                                      patient_id: care_address.patient_id,
                                      person_id: care_address.person_id,
                                      user_id: care_address.user_id,
                                      org_id: care_address.org_id,
                                      region_id: care_address.region_id,
                                      order_key: 0
    reload
  end

  def remove_care_address(care_address)
    care_address_list_entries.find_by!(care_address_id: care_address.id).destroy
    reload
  end

  def reorder_care_address_list(order, procedure)
    current_entries = care_address_list_entries.includes(:procedure, :org, :region,
                                                         :user).where(procedure_id: procedure.id).to_a
    order.each_with_index do |pt, i|
      current = current_entries.find { |x| x.procedure_id.to_s == pt }
      current.update order_key: i
    end
    reload
  end

  # TIME_BEFORE_INACTIVE = 2.weeks

  # # # ToDo: create function to clear completed care
  # def clear_care_address_list(region)
  #   care_address_list_entries.where(region: region).destroy_all
  # end

  private

  def ordered_care_addresses(procedure)
    # n+1 join here
    base_care_address = CareAddress
    base_care_address.where(procedure_id: procedure.id)
                     .order(start_date: :asc)
    #  .reject(&:nil?)
  end
end
