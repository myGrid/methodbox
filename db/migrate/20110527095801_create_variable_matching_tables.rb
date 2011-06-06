class CreateVariableMatchingTables < ActiveRecord::Migration
  def self.up
   create_table :matched_variables do |t|
      t.integer :variable_id
      t.integer :target_variable_id
      t.integer :occurences
      t.timestamps
    end
  end

  def self.down
    drop_table :matched_variables
  end
end
