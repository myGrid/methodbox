class AddShibToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :shibboleth, :boolean
    add_column :users, :shibboleth_user_id, :string
  end

  def self.down
    remove_column :users, :shibboleth
    remove_column :users, :shibboleth_user_id
  end
end
