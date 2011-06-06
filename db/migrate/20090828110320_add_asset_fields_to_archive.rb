class AddAssetFieldsToArchive < ActiveRecord::Migration
  def self.up
    add_column :csvarchives, :contributor_type, :string
    add_column :csvarchives, :contributor_id, :integer
  end

  def self.down
  end
end
