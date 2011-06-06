class ChangeMediumToMedianInVariables < ActiveRecord::Migration
  def self.up
    rename_column :variables, :medium, :median
  end

  def self.down
    rename_column :variables, :median, :medium
  end
end
