class ChangeVariableFieldsToText < ActiveRecord::Migration
 def self.up
    change_column :variables, :dermethod, :text
    change_column :variables, :info, :text
  end

  def self.down
  end
end
