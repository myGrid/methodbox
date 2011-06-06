class AddArchivedByToVariables < ActiveRecord::Migration
  def self.up
    add_column :variables, :archived_by, :integer
  end

  def self.down
    drop_column :variables, :archived_by
  end
end
