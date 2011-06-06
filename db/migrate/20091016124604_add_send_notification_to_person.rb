class AddSendNotificationToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :send_notifications,    :boolean, :default => false
  end

  def self.down
    remove_column :people, :send_notifications
  end
end
