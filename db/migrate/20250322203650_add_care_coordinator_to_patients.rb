class AddCareCoordinatorToPatients < ActiveRecord::Migration[7.2]
  def change
    add_reference :patients, :care_coordinator, foreign_key: true
    add_reference :archived_patients, :care_coordinator, foreign_key: true
  end
end
