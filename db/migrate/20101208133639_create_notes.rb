class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.column :user_id, :integer
      t.column :notable_id, :integer
      t.column :notable_type, :string
      t.column :words, :text
      t.timestamps
    end
  end

  def self.down
    drop_table :notes
  end
end
