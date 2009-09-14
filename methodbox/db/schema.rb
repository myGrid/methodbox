# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090903131503) do

  create_table "annotation_attributes", :force => true do |t|
    t.string   "name",       :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "annotation_attributes", ["name"], :name => "index_annotation_attributes_on_name"

  create_table "annotation_value_seeds", :force => true do |t|
    t.integer  "attribute_id",                 :null => false
    t.string   "value",        :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "annotation_value_seeds", ["attribute_id"], :name => "index_annotation_value_seeds_on_attribute_id"

  create_table "annotation_versions", :force => true do |t|
    t.integer  "annotation_id",                                    :null => false
    t.integer  "version",                                          :null => false
    t.integer  "version_creator_id"
    t.string   "source_type",                      :default => "", :null => false
    t.integer  "source_id",                                        :null => false
    t.string   "annotatable_type",   :limit => 50, :default => "", :null => false
    t.integer  "annotatable_id",                                   :null => false
    t.integer  "attribute_id",                                     :null => false
    t.text     "value",                                            :null => false
    t.string   "value_type",         :limit => 50, :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "annotation_versions", ["annotation_id"], :name => "index_annotation_versions_on_annotation_id"

  create_table "annotations", :force => true do |t|
    t.string   "source_type",                      :default => "", :null => false
    t.integer  "source_id",                                        :null => false
    t.string   "annotatable_type",   :limit => 50, :default => "", :null => false
    t.integer  "annotatable_id",                                   :null => false
    t.integer  "attribute_id",                                     :null => false
    t.text     "value",                                            :null => false
    t.string   "value_type",         :limit => 50, :default => "", :null => false
    t.integer  "version",                                          :null => false
    t.integer  "version_creator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "annotations", ["annotatable_type", "annotatable_id"], :name => "index_annotations_on_annotatable_type_and_annotatable_id"
  add_index "annotations", ["attribute_id"], :name => "index_annotations_on_attribute_id"
  add_index "annotations", ["source_type", "source_id"], :name => "index_annotations_on_source_type_and_source_id"

  create_table "assets", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.integer  "project_id"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.string   "source_type"
    t.integer  "source_id"
    t.string   "quality"
    t.integer  "policy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_used_at"
  end

  create_table "avatars", :force => true do |t|
    t.string   "owner_type"
    t.integer  "owner_id"
    t.string   "original_filename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_blobs", :force => true do |t|
    t.binary "data", :limit => 2147483647
  end

  create_table "csvarchives", :force => true do |t|
    t.integer  "person_id"
    t.string   "title"
    t.text     "description"
    t.string   "content_type"
    t.integer  "content_blob_id"
    t.datetime "last_used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filename"
    t.string   "url"
    t.boolean  "complete"
    t.boolean  "failure"
    t.string   "contributor_type"
    t.integer  "contributor_id"
  end

  create_table "favourite_group_memberships", :force => true do |t|
    t.integer  "person_id"
    t.integer  "favourite_group_id"
    t.integer  "access_type",        :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "favourite_groups", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "favourites", :force => true do |t|
    t.integer  "asset_id"
    t.integer  "user_id"
    t.string   "model_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_memberships", :force => true do |t|
    t.integer  "person_id"
    t.integer  "work_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_memberships_roles", :id => false, :force => true do |t|
    t.integer "group_membership_id"
    t.integer "role_id"
  end

  create_table "people", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "skype_name"
    t.string   "web_page"
    t.text     "description"
    t.integer  "avatar_id"
    t.integer  "status_id",   :default => 0
    t.boolean  "is_pal",      :default => false
  end

  create_table "permissions", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.integer  "policy_id"
    t.integer  "access_type",      :limit => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "policies", :force => true do |t|
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.string   "name"
    t.integer  "sharing_scope",      :limit => 1
    t.integer  "access_type",        :limit => 1
    t.boolean  "use_custom_sharing"
    t.boolean  "use_whitelist"
    t.boolean  "use_blacklist"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.string   "name"
    t.string   "web_page"
    t.string   "wiki_page"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "avatar_id"
    t.integer  "default_policy_id"
  end

  create_table "relationships", :force => true do |t|
    t.string   "subject_type", :default => "", :null => false
    t.integer  "subject_id",                   :null => false
    t.string   "predicate",    :default => "", :null => false
    t.string   "object_type",  :default => "", :null => false
    t.integer  "object_id",                    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scripts", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "content_type"
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.integer  "content_blob_id"
    t.datetime "last_used_at"
    t.string   "original_filename"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :default => "", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "surveys", :force => true do |t|
    t.string   "title"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "content_type"
    t.string   "contributor_type"
    t.integer  "contributor_id"
    t.integer  "content_blob_id"
    t.integer  "script_id"
    t.string   "original_filename"
    t.text     "description"
    t.datetime "last_used_at"
    t.string   "year"
    t.string   "surveytype"
    t.string   "UKDA_summary"
    t.string   "headline_report"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.integer  "person_id"
    t.boolean  "is_admin",                                :default => false
    t.boolean  "can_edit_projects",                       :default => false
    t.boolean  "can_edit_institutions",                   :default => false
    t.string   "reset_password_code"
    t.datetime "reset_password_code_until"
  end

  create_table "variable_lists", :force => true do |t|
    t.integer  "csvarchive_id"
    t.integer  "variable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "variables", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "survey_id"
    t.string   "label"
    t.integer  "csvarchive_id"
  end

  create_table "watched_variables", :force => true do |t|
    t.integer  "person_id"
    t.integer  "variable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
