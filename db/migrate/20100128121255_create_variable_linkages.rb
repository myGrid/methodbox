class CreateVariableLinkages < ActiveRecord::Migration
    def self.up
    create_table :variable_linkages do |t|
      t.integer :variable_link_id
      t.integer :variable_id
      t.timestamps
    end
  end

  def self.down
    drop_table :variable_linkages
  end
end