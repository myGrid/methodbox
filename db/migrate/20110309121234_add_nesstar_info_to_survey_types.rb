class AddNesstarInfoToSurveyTypes < ActiveRecord::Migration
  def self.up
    add_column :survey_types, :nesstar_uri, :string
    add_column :survey_types, :nesstar_id, :string
  end

  def self.down
    remove_column :survey_types, :nesstar_uri
    remove_column :survey_types, :nesstar_id
  end
end
