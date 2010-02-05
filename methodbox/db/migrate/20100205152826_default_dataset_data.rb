require 'default_data_migration'


class DefaultDatasetData < DefaultDataMigration
  def self.model_class_name
    "Dataset"
  end
end