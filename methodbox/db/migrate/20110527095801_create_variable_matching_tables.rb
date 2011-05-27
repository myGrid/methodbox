class CreateVariableMatchingTables < ActiveRecord::Migration
  def self.up
    create_table :variable_matches do |t|
      t.integer :source_variable_id
    end

    create_table :matched_variable_lists do |t|
      t.integer :variable_match_id
      t.integer :target_variable_id
      t.integer :occurences
    end
  end

  def self.down
    drop_table :variable_matches
    drop_table :matched_variable_lists
  end
end
