class AddFilenameToArchive < ActiveRecord::Migration
  def self.up
    add_column :csvarchives, :filename, :string
    add_column :csvarchives, :url, :string
    add_column :csvarchives, :complete, :boolean
  end

  def self.down
    remove_column :csvarchives, :filename
  end
end
