class AddBlobToSurveys < ActiveRecord::Migration
  def self.up
    add_column :surveys, :contributor_type, :string
    add_column :surveys, :contributor_id, :integer
    add_column :surveys, :content_blob_id, :integer
  end

  def self.down
  end
end
