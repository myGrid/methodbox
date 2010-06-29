class AddCurrentVersionToVariables < ActiveRecord::Migration
  def self.up
    add_column :variables, :current_version, :integer
  end

  def self.down
    drop_column :variables, :current_version
  end
end
