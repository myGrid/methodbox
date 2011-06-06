class AddTimestampsToSurvey < ActiveRecord::Migration
  def self.up
    add_column :surveys, :last_used_at, :datetime
#    add_column :surveys, :created_at, :datetime
#    add_column :surveys, :updated_at, :datetime
  end

  def self.down
  end
end
