class AddUuidFilenameToDataset < ActiveRecord::Migration
  def self.up
    add_column :datasets, :uuid_filename, :string
  end

  def self.down
    drop_column :datasets, :uuid_filename
  end
end
