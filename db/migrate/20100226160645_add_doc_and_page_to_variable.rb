class AddDocAndPageToVariable < ActiveRecord::Migration
  def self.up
    add_column :variables, :document, :string
    add_column :variables, :page, :string
  end

  def self.down
  end
end
