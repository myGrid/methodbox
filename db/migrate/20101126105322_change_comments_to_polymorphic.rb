class ChangeCommentsToPolymorphic < ActiveRecord::Migration
  def self.up
    rename_column :comments, :resource_id, :commentable_id
    rename_column :comments, :resource_type, :commentable_type
  end

  def self.down
    rename_column :comments, :commentable_id, :resource_id
    rename_column :comments, :commentable_type, :resource_type
  end
end
