class CreateCartItems < ActiveRecord::Migration
  def self.up
    create_table :cart_items do |t|
      t.integer :user_id
      t.integer :variable_id
      t.timestamps
    end
    
    add_index :cart_items, :user_id, :unique => false
  end

  def self.down
    drop_table :cart_items
  end
end
