class CreateWorkgroups < ActiveRecord::Migration
  def self.up
    create_table "work_groups", :force => true do |t|
      t.string   "name"
      t.text "description"
      # t.integer  "institution_id"
      # t.integer  "project_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
    drop_table "work_groups"
  end
end
