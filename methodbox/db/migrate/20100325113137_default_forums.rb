require 'default_data_migration'

class DefaultForums < DefaultDataMigration
  def self.model_class_name
    "Forum"
  end
end