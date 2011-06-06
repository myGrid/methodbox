class RemoveTypeFromSurveys < ActiveRecord::Migration
  def self.up
    remove_column :surveys, :type
  end

  def self.down
    add_column :surveys, :type, :string
  end
end
