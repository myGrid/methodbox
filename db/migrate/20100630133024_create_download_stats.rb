class CreateDownloadStats < ActiveRecord::Migration
  def self.up
    create_table "downloads", :force => true do |t|
      t.integer "user_id"
      t.string "resource_type"
      t.integer "resource_id"
      t.timestamps
    end
  end

  def self.down
    drop_table "downloads"
  end
end
