class AddExtractIdToCartItemsAndVariableLists < ActiveRecord::Migration
  def self.up
    add_column :variable_lists, :extract_id, :integer
    add_column :cart_items, :extract_id, :integer
  end

  def self.down
    remove_column :variable_lists, :extract_id
    remove_column :cart_items, :extract_id
  end
end
