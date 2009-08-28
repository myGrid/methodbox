require 'default_data_migration'


class DefaultSurveyData < DefaultDataMigration
  def self.model_class_name
    "Survey"
#    Survey.rebuild_solr_index
  end
end