class AddManyFieldsToScripts < ActiveRecord::Migration
  def self.up
    add_column :scripts, :content_type, :string
    add_column :scripts, :contributor_type, :string
    add_column :scripts, :contributor_id, :integer
    add_column :scripts, :content_blob_id, :integer
    add_column :scripts, :last_used_at, :datetime
    add_column :scripts, :original_filename, :string
    
  end

  def self.down
  end
end
