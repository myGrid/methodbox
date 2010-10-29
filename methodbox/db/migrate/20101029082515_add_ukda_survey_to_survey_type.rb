class AddUkdaSurveyToSurveyType < ActiveRecord::Migration
  def self.up
    add_column :survey_types, :is_ukda, :boolean
  end

  def self.down
    remove_column :survey_types, :is_ukda
  end
end
