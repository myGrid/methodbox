class AddKeyVariableToDataset < ActiveRecord::Migration
  def self.up
    add_column :datasets, :key_variable, :string
  end

  def self.down
    remove_column :datasets, :key_variable
  end
end
