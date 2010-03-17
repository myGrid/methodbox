class CreateDatasetLists < ActiveRecord::Migration
  def self.up
     create_table :dataset_lists do |t|
       t.integer :user_search_id
       t.integer :dataset_id
       t.timestamps
     end
   end

   def self.down
     drop_table :dataset_lists
   end
end
