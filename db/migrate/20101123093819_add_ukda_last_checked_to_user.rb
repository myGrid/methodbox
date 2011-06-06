class AddUkdaLastCheckedToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :last_ukda_check, :DateTime
    add_column :users, :ukda_registered, :boolean
  end

  def self.down
    remove_column :users, :last_ukda_check
    remove_column :users, :ukda_registered
  end
end
