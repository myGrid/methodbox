class AddScriptToSurveys < ActiveRecord::Migration
  def self.up
    add_column :surveys,:script_id,:integer
  end

  def self.down
  end
end
