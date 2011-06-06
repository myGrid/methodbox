class SurveyHasASource < ActiveRecord::Migration
  def self.up
    add_column :surveys, :source, :string
  end

  def self.down
    remove_column :surveys, :source
  end
end
