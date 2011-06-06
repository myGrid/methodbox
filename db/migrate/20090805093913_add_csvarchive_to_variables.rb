class AddCsvarchiveToVariables < ActiveRecord::Migration
  def self.up
    add_column :variables, :csvarchive_id, :integer
  end

  def self.down
  end
end
