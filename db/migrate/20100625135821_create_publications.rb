class CreatePublications < ActiveRecord::Migration
  def self.up
    create_table "publications", :force => true do |t|
      t.integer  "pubmed_id"
      t.text     "title"
      t.text     "abstract"
      t.date     "published_date"
      t.string   "journal"
      t.string   "first_letter",     :limit => 1
      t.string   "contributor_type"
      t.integer  "contributor_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "last_used_at"
      t.string   "doi"
      t.string   "uuid"
    end
  end

  def self.down
    drop_table "publications"
  end
end
