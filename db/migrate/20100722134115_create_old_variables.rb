class CreateOldVariables < ActiveRecord::Migration
  def self.up
    create_table "archived_variables", :force => true do |t|
      t.integer "variable_id"
      t.string "reason"
      t.timestamps
    end
  end

  def self.down
    drop_table "archived_variables"
  end
end
