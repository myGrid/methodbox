class CreateAssetCreators < ActiveRecord::Migration
  def self.up
    create_table "assets_creators", :id => false, :force => true do |t|
      t.integer "asset_id"
      t.integer "creator_id"
    end
    
  end

  def self.down
    drop_table "assets_creators"
  end
end
