class AddDeletionFlagsToMessages < ActiveRecord::Migration
    def self.up
      add_column :messages, :deleted_by_sender,    :boolean, :default => false
      add_column :messages, :deleted_by_recipient, :boolean, :default => false
    end

    def self.down
      remove_column :messages, :deleted_by_sender
      remove_column :messages, :deleted_by_recipient
    end
  end
