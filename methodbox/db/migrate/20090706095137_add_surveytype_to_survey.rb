class AddSurveytypeToSurvey < ActiveRecord::Migration
  def self.up
    add_column :surveys, :surveytype, :string
  end

  def self.down
  end
end
