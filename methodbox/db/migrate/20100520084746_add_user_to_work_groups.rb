class AddUserToWorkGroups < ActiveRecord::Migration
  def self.up
        add_column :work_groups, :user_id, :integer
  end

  def self.down
    drop_column :work_groups
  end
end
