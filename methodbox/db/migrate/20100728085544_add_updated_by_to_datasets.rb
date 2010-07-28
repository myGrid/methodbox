class AddUpdatedByToDatasets < ActiveRecord::Migration
  def self.up
        add_column :datasets, :updated_by, :integer
  end

  def self.down
    drop_column :datasets, :updated_by
  end
end
