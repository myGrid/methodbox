class CreateSurveyTypes < ActiveRecord::Migration
  def self.up
    create_table "survey_types", :force => true do |t|
      t.string "description"
      t.string "name"
      t.string "shortname"
      t.timestamps
    end
  end

  def self.down
    drop_table "survey_types"
  end
end
