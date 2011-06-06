class AddInfoToVariable < ActiveRecord::Migration
  def self.up
    add_column :variables, :info, :string
  end

  def self.down
  end
end
