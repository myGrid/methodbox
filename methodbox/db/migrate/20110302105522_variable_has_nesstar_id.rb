class VariableHasNesstarId < ActiveRecord::Migration
  def self.up
    add_column :variables, :nesstar_id, :string
  end

  def self.down
    remove_column :variables, :nesstar_id
  end
end
