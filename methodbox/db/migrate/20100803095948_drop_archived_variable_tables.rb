class DropArchivedVariableTables < ActiveRecord::Migration
  def self.up
    drop_table :archived_variables
    drop_table :extract_variable_archives
  end

  def self.down
  end
end
