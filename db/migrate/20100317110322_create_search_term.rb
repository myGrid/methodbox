class CreateSearchTerm < ActiveRecord::Migration
  def self.up
    create_table :search_terms do |t|
      t.string :term
      t.timestamps
    end
  end

  def self.down
    drop_table :search_terms
  end
end
