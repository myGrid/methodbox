class AddUserToLinks < ActiveRecord::Migration
  def self.up
    add_column :links, :user_id, :integer
  end

  def self.down
    remove_column :links, :user_id
  end
end
