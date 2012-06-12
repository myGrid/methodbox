class SurveyHasWeightingGuide < ActiveRecord::Migration
  def self.up
    add_column :surveys, :weighting_guide, :string
  end

  def self.down
    remove_column :surveys, :weighting_guide
  end
end
