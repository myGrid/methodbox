class CreateSurveyListsAndAssociations < ActiveRecord::Migration
 def self.up
    create_table :survey_lists do |t|
      t.integer :csvarchive_id
      t.integer :survey_id
      t.timestamps
    end
  end

  def self.down
    drop_table :survey_lists
  end
end
