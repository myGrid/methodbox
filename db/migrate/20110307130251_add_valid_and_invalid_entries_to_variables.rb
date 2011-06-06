class AddValidAndInvalidEntriesToVariables < ActiveRecord::Migration
  def self.up
    add_column :variables, :valid_entries, :integer
    add_column :variables, :invalid_entries, :integer
  end

  def self.down
    remove_column :variables, :valid_entries
    remove_column :variables, :invalid_entries
  end
end
