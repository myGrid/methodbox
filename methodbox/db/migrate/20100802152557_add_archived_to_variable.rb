class AddArchivedToVariable < ActiveRecord::Migration
  def self.up
    add_column :variables, :is_archived, :boolean, :default=>false
  end

  def self.down
    drop_column :variables, :is_archived
  end
end
