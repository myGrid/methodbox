class AddFieldsToArchivedVariables < ActiveRecord::Migration
  def self.up
    add_column :archived_variables, :name, :string
    add_column :archived_variables, :value, :string
    add_column :archived_variables, :dataset_id, :integer
    add_column :archived_variables, :label, :string
    add_column :archived_variables, :category, :string
    add_column :archived_variables, :dertype, :string
    add_column :archived_variables, :dermethod, :text
    add_column :archived_variables, :info, :text
    add_column :archived_variables, :document, :string
    add_column :archived_variables, :page, :string
  end

  def self.down
    drop_column :archived_variables, :name
    drop_column :archived_variables, :value
    drop_column :archived_variables, :dataset_id
    drop_column :archived_variables, :label
    drop_column :archived_variables, :category
    drop_column :archived_variables, :dertype
    drop_column :archived_variables, :dermethod
    drop_column :archived_variables, :info
    drop_column :archived_variables, :document
    drop_column :archived_variables, :page
  end
end
