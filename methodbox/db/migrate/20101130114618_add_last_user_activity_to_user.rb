class AddLastUserActivityToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :last_user_activity, :datetime
  end

  def self.down
    remove_column :users, :last_user_activity
  end
end
