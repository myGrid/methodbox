class AddDataProviderTypeToSurveys < ActiveRecord::Migration
  def self.up
    add_column :surveys, :data_provider_id, :integer
  end

  def self.down
    remove_column :surveys, :data_provider_id
  end
end
