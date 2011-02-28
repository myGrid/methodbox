class ChangeDescriptionToTextInDatasets < ActiveRecord::Migration
  def self.up
    change_column :datasets, :description, :text
  end

  def self.down
    change_column :datasets, :description, :string
  end
end
