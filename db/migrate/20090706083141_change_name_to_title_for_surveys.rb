class ChangeNameToTitleForSurveys < ActiveRecord::Migration
  def self.up
    rename_column :surveys, :name, :title
  end

  def self.down
  end
end
