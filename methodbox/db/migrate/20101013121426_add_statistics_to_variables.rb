class AddStatisticsToVariables < ActiveRecord::Migration
  def self.up
    add_column :variables, :data_file, :string, :limit => 100
    add_column :variables, :none_values_distribution_file, :string, :limit => 100
    add_column :variables, :values_distribution_file, :string, :limit => 100
    add_column :variables, :mean, :float
    add_column :variables, :medium, :float
    add_column :variables, :mode, :float
    add_column :variables, :standard_deviation, :float
    add_column :variables, :min_value, :float
    add_column :variables, :max_value, :float
    add_column :variables, :number_of_unique_entries, :integer
    add_column :variables, :number_of_unique_values, :integer
    add_column :variables, :number_of_blank_rows, :integer
  end

  def self.down
    remove_column :variables, :data_file
    remove_column :variables, :none_values_distribution_file
    remove_column :variables, :values_distribution_file
    remove_column :variables, :mean
    remove_column :variables, :medium
    remove_column :variables, :mode
    remove_column :variables, :standard_deviation
    remove_column :variables, :min_value
    remove_column :variables, :max_value
    remove_column :variables, :number_of_unique_entries
    remove_column :variables, :number_of_unique_values
    remove_column :variables, :number_of_blank_rows
  end
end
