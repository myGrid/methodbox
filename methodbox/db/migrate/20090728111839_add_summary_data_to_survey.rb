class AddSummaryDataToSurvey < ActiveRecord::Migration
  def self.up
    add_column :surveys, :UKDA_summary, :string
    add_column :surveys, :headline_report, :string
  end

  def self.down
  end
end
