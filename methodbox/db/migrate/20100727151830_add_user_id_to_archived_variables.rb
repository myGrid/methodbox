class AddUserIdToArchivedVariables < ActiveRecord::Migration
  def self.up
    add_column :archived_variables, :user_id, :integer
  end

  def self.down
    drop_column :archived_variables, :user_id
  end
end
