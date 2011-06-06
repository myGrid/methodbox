class AddMethodTypeToScript < ActiveRecord::Migration
  def self.up
    add_column :scripts, :method_type, :string
  end

  def self.down
  end
end
