class CreateLinks < ActiveRecord::Migration
  
  def self.up
  create_table "links", :force => true do |t|
    t.string   "subject_type",       :null => false
    t.integer  "subject_id",         :null => false
    t.string   "predicate",          :null => false
    t.string   "object_type",        :null => false
    t.integer  "object_id",          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subject_field_name"
    t.string   "object_field_name"
  end
end

  def self.down
    drop_table "links"
  end
end
