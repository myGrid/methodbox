class AddOriginalFilenameChangeDescriptionToSurvey < ActiveRecord::Migration
  def self.up
    add_column :surveys, :original_filename, :string
    add_column :surveys, :description, :text
  end

  def self.down
  end
end
