class DeleteRolesForGroups < ActiveRecord::Migration
  def self.up
    drop_table "group_memberships_roles"
  end

  def self.down
  end
end
