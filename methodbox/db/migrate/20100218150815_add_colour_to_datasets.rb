class AddColourToDatasets < ActiveRecord::Migration
  def self.up
     add_column :datasets, :colour, :string
  end

  def self.down
     remove_column :datasets, :colour, :string
  end
end
