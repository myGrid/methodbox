class RenameSurveyToDatasetInVariables < ActiveRecord::Migration
  def self.up
    rename_column :variables, :survey_id, :dataset_id
  end

  def self.down
  end
end
