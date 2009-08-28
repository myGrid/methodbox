class AddLabelToVariable < ActiveRecord::Migration
  def self.up
    add_column :variables, :label, :string
  end

  def self.down
  end
end
