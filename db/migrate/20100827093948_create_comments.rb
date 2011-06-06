class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.column :user_id, :integer
      t.column :resource_id, :integer
      t.column :resource_type, :string
      t.column :words, :text
      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end
