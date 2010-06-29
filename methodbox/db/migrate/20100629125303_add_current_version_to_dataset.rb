class AddCurrentVersionToDataset < ActiveRecord::Migration
  def self.up
    add_column :datasets, :current_version, :integer
  end

  def self.down
    remove_column :datasets, :current_version
  end
end
