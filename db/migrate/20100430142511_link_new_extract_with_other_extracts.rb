class LinkNewExtractWithOtherExtracts < ActiveRecord::Migration
  def self.up
    create_table "extract_to_extract_links" do |t|
      t.column "source_id", :integer, :null => false
      t.column "target_id",   :integer, :null => false
    end
    
  end

  def self.down
    drop_table "extract_to_extract_links"
  end
end
