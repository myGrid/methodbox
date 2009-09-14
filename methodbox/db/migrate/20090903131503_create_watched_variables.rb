class CreateWatchedVariables < ActiveRecord::Migration
   def self.up
    create_table :watched_variables do |t|
      t.integer :person_id
      t.integer :variable_id
      t.timestamps
    end
  end

  def self.down
    drop_table :watched_variables
  end
end
