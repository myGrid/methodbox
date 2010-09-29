class ChangePersonToUserInCsvarchives < ActiveRecord::Migration
  def self.up
    rename_column :csvarchives, :person_id, :user_id
  end

  def self.down
    rename_column :csvarchives, :user_id, :person_id
  end
end
