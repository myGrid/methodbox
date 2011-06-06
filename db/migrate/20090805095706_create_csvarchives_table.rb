class CreateCsvarchivesTable < ActiveRecord::Migration
  def self.up
      create_table :csvarchives do |t|
      t.integer :person_id
      t.string :title
      t.text :description
      t.string :content_type
      t.integer :content_blob_id

      t.datetime :last_used_at

      t.timestamps
    end
  end

  def self.down
    drop_table :csvarchives
  end
end