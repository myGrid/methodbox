class CreateValueDomainForVariables < ActiveRecord::Migration
  def self.up
    create_table "value_domains", :force => true do |t|
      t.integer "variable_id"
      t.string "label"
      t.string "value"
      t.timestamps
    end
  end

  def self.down
    drop_table :value_domains
  end
end
