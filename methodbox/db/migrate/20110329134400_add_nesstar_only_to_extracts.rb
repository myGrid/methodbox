class AddNesstarOnlyToExtracts < ActiveRecord::Migration
  def self.up
    add_column :csvarchives, :nesstar_only, :boolean
  end

  def self.down
    remove_column :csvarchives, :nesstar_only
  end
end
