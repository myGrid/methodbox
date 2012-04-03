class ChangeYearToIntInDataset < ActiveRecord::Migration
  def self.up
    change_column :datasets, :year, :integer
  end

  def self.down
    change_column :datasets, :year, :string
  end
end
