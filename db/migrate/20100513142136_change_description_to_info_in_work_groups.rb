class ChangeDescriptionToInfoInWorkGroups < ActiveRecord::Migration
  def self.up
    rename_column :work_groups, :description, :info
  end

  def self.down
    rename_column :work_groups, :info, :description
  end
end
