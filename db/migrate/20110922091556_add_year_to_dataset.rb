class AddYearToDataset < ActiveRecord::Migration
  def self.up
    add_column :datasets, :year, :string
  end

  def self.down
    drop_column :datasets, :year
  end
end
