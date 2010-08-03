class CreateExtractVariableArchive < ActiveRecord::Migration
  def self.up
      create_table "extract_variable_archives", :force => true do |t|
        t.integer "csvarchive_id"
        t.integer "variable_id"
        t.timestamps
      end
  end

  def self.down
    drop_table "extract_variable_archives"
  end
end
