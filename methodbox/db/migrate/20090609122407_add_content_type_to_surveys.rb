class AddContentTypeToSurveys < ActiveRecord::Migration
  def self.up
    add_column :surveys, :content_type, :string
  end

  def self.down
  end
end
