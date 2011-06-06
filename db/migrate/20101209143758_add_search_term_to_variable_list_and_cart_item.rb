class AddSearchTermToVariableListAndCartItem < ActiveRecord::Migration
  def self.up
    add_column :variable_lists, :search_term, :string
    add_column :cart_items, :search_term, :string
  end

  def self.down
    remove_column :variable_lists, :search_term
    remove_column :cart_items, :search_term
  end
end
