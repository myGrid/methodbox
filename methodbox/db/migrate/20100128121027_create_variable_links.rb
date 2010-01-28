class CreateVariableLinks < ActiveRecord::Migration
    def self.up
    create_table :variable_links do |t|
      t.integer :person_id
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :variable_links
  end
end