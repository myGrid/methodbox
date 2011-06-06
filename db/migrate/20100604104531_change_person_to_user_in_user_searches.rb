class ChangePersonToUserInUserSearches < ActiveRecord::Migration
  def self.up
        rename_column :user_searches, :person_id, :user_id
  end

  def self.down
        rename_column :user_searches, :user_id, :person_id
  end
end
