class AddReplacedByToVariables < ActiveRecord::Migration
  def self.up
    add_column :variables, :replaced_by, :integer
  end

  def self.down
    drop_column :variables, :replaced_by
  end
end
