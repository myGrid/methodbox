class AddHasDataBooleanToDatasets < ActiveRecord::Migration
  def self.up
      add_column :datasets, :has_data, :boolean
  end

  def self.down
    drop_column :datasets, :has_data
  end
end
