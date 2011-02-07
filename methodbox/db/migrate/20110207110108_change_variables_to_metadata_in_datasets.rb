class ChangeVariablesToMetadataInDatasets < ActiveRecord::Migration
  def self.up
      rename_column :datasets, :has_variables, :has_metadata
  end

  def self.down
      rename_column :datasets, :has_metadata, :has_variables
  end
end
