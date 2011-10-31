#has the data extract been checked to see which vars match other extracts
class AddSimilarityCheckedToDataExtracts < ActiveRecord::Migration
  def self.up
    add_column :csvarchives, :similarity_checked, :boolean, :default => false
  end

  def self.down
    remove_column :csvarchives, :similarity_checked
  end
end
