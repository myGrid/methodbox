class CreateVariableListAndAssociations < ActiveRecord::Migration
  def self.up
    create_table :variable_lists do |t|
      t.integer :csvarchive_id
      t.integer :variable_id
      t.timestamps
    end
  end

  def self.down
    drop_table :variable_lists
  end
end
