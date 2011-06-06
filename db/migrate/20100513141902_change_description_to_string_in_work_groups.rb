class ChangeDescriptionToStringInWorkGroups < ActiveRecord::Migration
  def self.up
    change_column :work_groups, :description, :string
  end

  def self.down
    change_column :work_groups, :description, :text
  end
end
