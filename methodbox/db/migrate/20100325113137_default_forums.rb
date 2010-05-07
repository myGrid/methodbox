require 'default_data_migration'

#Use note: You must set up savage beast forums first
#rake savage_beast:bootstrap_db

class DefaultForums < DefaultDataMigration
  def self.model_class_name
    "Forum"
  end
end