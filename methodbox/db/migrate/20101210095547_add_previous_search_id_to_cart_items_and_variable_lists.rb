class AddPreviousSearchIdToCartItemsAndVariableLists < ActiveRecord::Migration
  def self.up
    add_column :variable_lists, :user_search_id, :integer
    add_column :cart_items, :user_search_id, :integer
  end

  def self.down
    remove_column :variable_lists, :user_search_id
    remove_column :cart_items, :user_search_id
  end
end
