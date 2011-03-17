class AddNesstarStatusToArchive < ActiveRecord::Migration
  def self.up
    add_column :csvarchives, :contains_nesstar_variables, :boolean
  end

  def self.down
    remove_column :csvarchives, :contains_nesstar_variables
  end
end
