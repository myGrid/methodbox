class AddTotalEntriesToVariable < ActiveRecord::Migration
  def self.up
    add_column :variables, :total_entries, :integer
  end

  def self.down
    drop_column :variables, :total_entries
  end
end
