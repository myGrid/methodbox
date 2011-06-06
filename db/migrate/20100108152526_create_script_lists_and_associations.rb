class CreateScriptListsAndAssociations < ActiveRecord::Migration
    def self.up
    create_table :script_lists do |t|
      t.integer :csvarchive_id
      t.integer :script_id
      t.timestamps
    end
  end

  def self.down
    drop_table :script_lists
  end
end
