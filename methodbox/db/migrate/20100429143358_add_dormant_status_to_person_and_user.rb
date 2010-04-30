class AddDormantStatusToPersonAndUser < ActiveRecord::Migration
  def self.up
    add_column :people, :dormant, :boolean, :default=>false
    add_column :users, :dormant, :boolean, :default=>false
  end

  def self.down
    remove_column :people, :dormant
    remove_column :users, :dormant
  end
end
