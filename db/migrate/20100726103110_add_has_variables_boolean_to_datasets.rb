class AddHasVariablesBooleanToDatasets < ActiveRecord::Migration
  def self.up
    add_column :datasets, :has_variables, :boolean
  end

  def self.down
    remove_column :datasets, :has_variables
  end
end
