class CreateSurveyToScriptListsAndAssociations < ActiveRecord::Migration
 def self.up
    create_table :survey_to_script_lists do |t|
      t.integer :script_id
      t.integer :survey_id
      t.timestamps
    end
  end

  def self.down
    drop_table :survey_to_script_lists
  end
end