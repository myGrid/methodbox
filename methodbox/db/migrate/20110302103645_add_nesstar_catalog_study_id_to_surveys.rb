class AddNesstarCatalogStudyIdToSurveys < ActiveRecord::Migration
  def self.up
    add_column :surveys, :nesstar_id, :string
    add_column :datasets, :nesstar_id, :string
    add_column :variables, :nesstar_file, :string
  end

  def self.down
    remove_column :surveys, :nesstar_id
    remove_column :datasets, :nesstar_id
    remove_column :variables, :nesstar_file
  end
end
