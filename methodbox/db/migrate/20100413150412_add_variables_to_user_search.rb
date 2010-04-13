class AddVariablesToUserSearch < ActiveRecord::Migration
  def self.up
     create_table :search_variable_lists do |t|
       t.integer :user_search_id
       t.integer :variable_id
       t.timestamps
     end
   end

   def self.down
     drop_table :search_variable_lists
   end
end
