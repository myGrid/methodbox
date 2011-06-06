class AddIntervalToVariables < ActiveRecord::Migration
  def self.up
    add_column :variables, :interval, :string
  end

  def self.down
    remove_column :variables, :interval
  end
end
