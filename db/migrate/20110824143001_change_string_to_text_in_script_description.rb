class ChangeStringToTextInScriptDescription < ActiveRecord::Migration
  def self.up
    change_column :scripts, :description, :text
  end

  def self.down
    change_column :scripts, :description, :string
  end
end
