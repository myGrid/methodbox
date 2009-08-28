class AddYearToSurvey < ActiveRecord::Migration
  def self.up
    add_column :surveys, :year, :string
  end

  def self.down
  end
end
