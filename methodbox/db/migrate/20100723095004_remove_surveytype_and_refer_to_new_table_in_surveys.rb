class RemoveSurveytypeAndReferToNewTableInSurveys < ActiveRecord::Migration
  def self.up
      remove_column :surveys, :surveytype
      add_column :surveys, :survey_type_id, :integer
  end

  def self.down
    remove_column :surveys, :survey_type_id
    add_column :surveys, :surveytype, :string
  end
end
