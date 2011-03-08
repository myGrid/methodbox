class AddNesstarUriToSurveys < ActiveRecord::Migration
  def self.up
    add_column :surveys, :nesstar_uri, :string
    add_column :datasets, :nesstar_uri, :string
  end

  def self.down
    remove_column :surveys, :nesstar_uri
    remove_column :datasets, :nesstar_uri
  end
end
