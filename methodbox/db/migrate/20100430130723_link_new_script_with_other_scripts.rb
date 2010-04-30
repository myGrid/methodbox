class LinkNewScriptWithOtherScripts < ActiveRecord::Migration
  def self.up
    create_table "script_to_script_links" do |t|
      t.column "source_id", :integer, :null => false
      t.column "target_id",   :integer, :null => false
    end
    
  end

  def self.down
    drop_table "script_to_script_links"
  end
end
