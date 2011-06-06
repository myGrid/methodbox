class AddArchivedTimeToVariable < ActiveRecord::Migration
  def self.up
    add_column :variables, :archived_on, :datetime
  end

  def self.down
    drop_column :variables
  end
end
