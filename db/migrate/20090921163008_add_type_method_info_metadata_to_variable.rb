class AddTypeMethodInfoMetadataToVariable < ActiveRecord::Migration
  def self.up
    add_column :variables, :category, :string
     add_column :variables, :dertype, :string
      add_column :variables, :dermethod, :string
  end

  def self.down
  end
end
