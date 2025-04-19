class PortQcHousingRelationships < ActiveRecord::Migration[7.2]
  def change
    add_reference :volunteers, :qc_housing, foreign_key: true

    # TODO: revisit this relationship
    # add_reference :care_coordinators, :qc_housing, foreign_key: true

    add_reference :care_addresses, :qc_housing, foreign_key: true
  end
end
