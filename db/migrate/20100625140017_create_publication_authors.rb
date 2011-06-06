class CreatePublicationAuthors < ActiveRecord::Migration
  def self.up
    create_table "publication_authors", :force => true do |t|
      t.string   "first_name"
      t.string   "last_name"
      t.integer  "publication_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    drop_table "publication_authors"
  end
end
