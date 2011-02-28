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

ActiveRecord::Schema.define(:version => 20110228134900) do

  create_table "activity_limits", :force => true do |t|
    t.string   "contributor_type", :null => false
    t.integer  "contributor_id",   :null => false
    t.string   "limit_feature",    :null => false
    t.integer  "limit_max"
    t.integer  "limit_frequency"
    t.integer  "current_count",    :null => false
    t.datetime "reset_after"
    t.datetime "promote_after"
  end

  create_table "annotation_attributes", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "annotation_attributes", ["name"], :name => "index_annotation_attributes_on_name"

  create_table "annotation_value_seeds", :force => true do |t|
    t.integer  "attribute_id", :null => false
    t.string   "value",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "annotation_value_seeds", ["attribute_id"], :name => "index_annotation_value_seeds_on_attribute_id"

  create_table "annotation_versions", :force => true do |t|
    t.integer  "annotation_id",                    :null => false
    t.integer  "version",                          :null => false
    t.integer  "version_creator_id"
    t.string   "source_type",                      :null => false
    t.integer  "source_id",                        :null => false
    t.string   "annotatable_type",   :limit => 50, :null => false
    t.integer  "annotatable_id",                   :null => false
    t.integer  "attribute_id",                     :null => false
    t.text     "value",                            :null => false
    t.string   "value_type",         :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "annotation_versions", ["annotation_id"], :name => "index_annotation_versions_on_annotation_id"

  create_table "annotations", :force => true do |t|
    t.string   "source_type",                      :null => false
    t.integer  "source_id",                        :null => false
    t.string   "annotatable_type",   :limit => 50, :null => false
    t.integer  "annotatable_id",                   :null => false
    t.integer  "attribute_id",                     :null => false
    t.text     "value",                            :null => false
    t.string   "value_type",         :limit => 50, :null => false
    t.integer  "version",                          :null => false
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

  create_table "assets_creators", :id => false, :force => true do |t|
    t.integer "asset_id"
    t.integer "creator_id"
  end

  create_table "avatars", :force => true do |t|
    t.string   "owner_type"
    t.integer  "owner_id"
    t.string   "original_filename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cart_items", :force => true do |t|
    t.integer  "user_id"
    t.integer  "variable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "search_term"
    t.integer  "extract_id"
    t.integer  "user_search_id"
  end

  add_index "cart_items", ["user_id"], :name => "index_cart_items_on_user_id"

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.text     "words"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "content_blobs", :force => true do |t|
    t.binary "data", :limit => 2147483647
  end

  create_table "csvarchives", :force => true do |t|
    t.integer  "user_id"
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

  create_table "dataset_lists", :force => true do |t|
    t.integer  "user_search_id"
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "datasets", :force => true do |t|
    t.integer  "survey_id"
    t.string   "name"
    t.string   "filename"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "colour"
    t.string   "key_variable"
    t.integer  "current_version"
    t.boolean  "has_metadata"
    t.boolean  "has_data"
    t.integer  "updated_by"
    t.string   "uuid_filename"
    t.string   "reason_for_update"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.string   "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["locked_by"], :name => "index_delayed_jobs_on_locked_by"

  create_table "downloads", :force => true do |t|
    t.integer  "user_id"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "extract_to_extract_links", :force => true do |t|
    t.integer "source_id", :null => false
    t.integer "target_id", :null => false
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

  create_table "forums", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.integer "topics_count",     :default => 0
    t.integer "posts_count",      :default => 0
    t.integer "position"
    t.text    "description_html"
  end

  create_table "group_memberships", :force => true do |t|
    t.integer  "person_id"
    t.integer  "work_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
    t.integer  "user_id"
  end

  create_table "messages", :force => true do |t|
    t.integer  "from"
    t.integer  "to"
    t.string   "subject"
    t.text     "body"
    t.integer  "reply_id"
    t.datetime "created_at"
    t.datetime "read_at"
    t.text     "body_html"
    t.boolean  "deleted_by_sender",    :default => false
    t.boolean  "deleted_by_recipient", :default => false
  end

  create_table "moderatorships", :force => true do |t|
    t.integer "forum_id"
    t.integer "user_id"
  end

  add_index "moderatorships", ["forum_id"], :name => "index_moderatorships_on_forum_id"

  create_table "monitorships", :force => true do |t|
    t.integer "topic_id"
    t.integer "user_id"
    t.boolean "active",   :default => true
  end

  create_table "notes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "notable_id"
    t.string   "notable_type"
    t.text     "words"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.integer  "status_id",          :default => 0
    t.boolean  "is_pal",             :default => false
    t.boolean  "send_notifications", :default => false
    t.boolean  "dormant",            :default => false, :null => false
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

  create_table "posts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "topic_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "forum_id"
    t.text     "body_html"
  end

  add_index "posts", ["forum_id", "created_at"], :name => "index_posts_on_forum_id"
  add_index "posts", ["topic_id", "created_at"], :name => "index_posts_on_topic_id"
  add_index "posts", ["user_id", "created_at"], :name => "index_posts_on_user_id"

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

  create_table "publication_authors", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "publication_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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

  create_table "recommendations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "recommendable_id"
    t.string   "recommendable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relationships", :force => true do |t|
    t.string   "subject_type", :null => false
    t.integer  "subject_id",   :null => false
    t.string   "predicate",    :null => false
    t.string   "object_type",  :null => false
    t.integer  "object_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "script_lists", :force => true do |t|
    t.integer  "csvarchive_id"
    t.integer  "script_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "script_to_script_links", :force => true do |t|
    t.integer "source_id", :null => false
    t.integer "target_id", :null => false
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
    t.string   "method_type"
  end

  create_table "search_terms", :force => true do |t|
    t.string   "term"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "search_variable_lists", :force => true do |t|
    t.integer  "user_search_id"
    t.integer  "variable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "stata_do_files", :force => true do |t|
    t.binary  "data",          :limit => 2147483647
    t.string  "name"
    t.integer "csvarchive_id"
  end

  create_table "survey_lists", :force => true do |t|
    t.integer  "csvarchive_id"
    t.integer  "survey_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "survey_to_script_lists", :force => true do |t|
    t.integer  "script_id"
    t.integer  "survey_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "survey_types", :force => true do |t|
    t.string   "description"
    t.string   "name"
    t.string   "shortname"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_ukda"
  end

  create_table "surveys", :force => true do |t|
    t.string   "title"
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
    t.string   "UKDA_summary"
    t.string   "headline_report"
    t.integer  "survey_type_id"
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

  create_table "topics", :force => true do |t|
    t.integer  "forum_id"
    t.integer  "user_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hits",         :default => 0
    t.integer  "sticky",       :default => 0
    t.integer  "posts_count",  :default => 0
    t.datetime "replied_at"
    t.boolean  "locked",       :default => false
    t.integer  "replied_by"
    t.integer  "last_post_id"
  end

  add_index "topics", ["forum_id", "replied_at"], :name => "index_topics_on_forum_id_and_replied_at"
  add_index "topics", ["forum_id", "sticky", "replied_at"], :name => "index_topics_on_sticky_and_replied_at"
  add_index "topics", ["forum_id"], :name => "index_topics_on_forum_id"

  create_table "user_searches", :force => true do |t|
    t.integer  "user_id"
    t.string   "terms"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.integer  "posts_count",                             :default => 0
    t.datetime "last_seen_at"
    t.boolean  "dormant",                                 :default => false, :null => false
    t.datetime "last_ukda_check"
    t.boolean  "ukda_registered"
    t.datetime "last_user_activity"
    t.boolean  "shibboleth"
    t.string   "shibboleth_user_id"
  end

  create_table "value_domains", :force => true do |t|
    t.integer  "variable_id"
    t.string   "label"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "variable_linkages", :force => true do |t|
    t.integer  "variable_link_id"
    t.integer  "variable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "variable_links", :force => true do |t|
    t.integer  "person_id"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "variable_lists", :force => true do |t|
    t.integer  "csvarchive_id"
    t.integer  "variable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "search_term"
    t.integer  "extract_id"
    t.integer  "user_search_id"
  end

  create_table "variables", :force => true do |t|
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "dataset_id"
    t.string   "label"
    t.integer  "csvarchive_id"
    t.string   "category"
    t.string   "dertype"
    t.text     "dermethod"
    t.text     "info"
    t.string   "document"
    t.string   "page"
    t.integer  "current_version"
    t.integer  "updated_by"
    t.boolean  "is_archived",                                  :default => false
    t.string   "archived_reason"
    t.integer  "archived_by"
    t.datetime "archived_on"
    t.string   "update_reason"
    t.integer  "replaced_by"
    t.string   "data_file",                     :limit => 100
    t.string   "none_values_distribution_file", :limit => 100
    t.string   "values_distribution_file",      :limit => 100
    t.float    "mean"
    t.float    "medium"
    t.float    "mode"
    t.float    "standard_deviation"
    t.float    "min_value"
    t.float    "max_value"
    t.integer  "number_of_unique_entries"
    t.integer  "number_of_unique_values"
    t.integer  "number_of_blank_rows"
  end

  create_table "watched_variables", :force => true do |t|
    t.integer  "person_id"
    t.integer  "variable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "work_groups", :force => true do |t|
    t.string   "name"
    t.string   "info"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

end
