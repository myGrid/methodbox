class CreateScripts < ActiveRecord::Migration
  def self.up
    create_table :scripts do |t|
      t.string :title
      t.text :body
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :scripts
  end
end
