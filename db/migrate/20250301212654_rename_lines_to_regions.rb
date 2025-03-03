class RenameLinesToRegions < ActiveRecord::Migration[7.2]
  def change
    rename_table :lines, :regions
  end
end
