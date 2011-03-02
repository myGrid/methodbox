# Use delayed job. Add surveys from a nesstar catalogue that a user has selected

require 'nesstar-api'

module AddNesstarSurveysJob
  
  class StartJobTask < Struct.new(:datasets, :nesstar_url, :nesstar_catalog, :user_id, :base_host)
    
    
    cattr_accessor :logger
    self.logger = RAILS_DEFAULT_LOGGER
    
    def perform
      begin
        n = Nesstar::Api::CatalogApi.new
        #get all the catalogs and datasets
        nodes = n.get_nodes nesstar_url, nesstar_catalog
        surveys_hash = Hash.new
        survey_types_hash = Hash.new
        #get the parentage of the datasets
        n.parse_surveys_from_nodes nodes.root, surveys_hash, survey_types_hash
        datasets.each do |dataset|
          dataset_info = n.get_simple_study_information nesstar_url, dataset
          surveys_hash.each_key do |survey|
            datasets_array = surveys_hash[survey].collect {|x| x.split('/').last}
            if datasets_array.include?(dataset)
              begin
              #parent of the dataset
              parent = survey
              parent_info = n.get_catalog_information nesstar_url, survey
              catalog_info = n.get_catalog_information nesstar_url, nesstar_catalog
              survey_types_hash.each_key do |survey_type|
                survey_types_array = survey_types_hash[survey_type].collect {|x| x.split('/').last}
                if survey_types_array.include?(survey.split('/').last)
                  #survey type of the parent
                  survey_parent = survey_type
                  survey_type_info = n.get_catalog_information nesstar_url, survey_type unless survey_type == 'none'
                  logger.info Time.now.to_s + " : retrieving info for " + dataset + ", " + dataset_info.title + ", with parent " + parent_info.label + ", " + catalog_info.label + ", and survey type " + survey_type
                  
                  study = n.get_study_information nesstar_url, dataset
                  
                  
                  #TODO - pass in ukda status
                  #find exisitng survey type or create new one
                  if survey_type_info != nil
                    catalog_survey_types = SurveyType.all(:conditions=>{:name => survey_type_info.label})
                    if catalog_survey_types.empty?
                      catalog_survey_type = SurveyType.new(:name => survey_type_info.label, :description => survey_type_info.description)
                      catalog_survey_type.save
                    else
                      catalog_survey_type = catalog_survey_types[0]
                    end
                  else
                    catalog_survey_types = SurveyType.all(:conditions=>{:name => "none"})
                    if catalog_survey_types.size == 0
                      catalog_survey_type = SurveyType.new(:name => 'none', :description => 'Surveys which do not have a specified survey type')
                      catalog_survey_type.save
                    else
                      catalog_survey_type = catalog_survey_types[0]
                    end
                  end
                  #find existing survey or create new one
                  catalog_surveys = Survey.all(:conditions => {:title => parent_info.label, :survey_type_id => catalog_survey_type.id})
                  if catalog_surveys.empty?
                    catalog_survey = Survey.new(:title => parent_info.label, :description => parent_info.description, :survey_type_id => catalog_survey_type.id, :year => 'N/A')
                    catalog_survey.save
                    #TODO user can define policy when adding the surveys
                    policy = Policy.create(:name => "survey_policy", :sharing_scope => 3, :use_custom_sharing => false, :access_type => 2, :contributor => User.find(user_id))
                    catalog_survey.asset.policy = policy
                    policy.save
                    catalog_survey.asset.contributor_type='User'
                    catalog_survey.asset.contributor_id = user_id
                    catalog_survey.asset.save
                  else
                    catalog_survey = catalog_surveys[0]
                  end
                  #create new dataset and save it
                  catalog_datasets = Dataset.all(:conditions => {:filename => study.variables[0].file, :name => study.title, :survey_id => catalog_survey.id})
                  if catalog_datasets.empty?
                    catalog_dataset = Dataset.new(:current_version => 1, :filename => study.variables[0].file, :name => study.title, :description => study.abstract, :survey => catalog_survey)
                    catalog_dataset.save
                  else
                    #this should be a new dataset so throw exception and carry on to the next
                    raise 'This dataset has already been added'
                  end
                  #create variables for the dataset
                  study.variables.each do |variable|
                    var = Variable.new(:name=> variable.name, :value => variable.label, :category => variable.group, :dataset => catalog_dataset)
                    logger.info Time.now.to_s + " : saving variable " + variable.name + " from " + study.title
                    var.save
                  end
                  break
                end
              end
              break
            rescue Exception => e
              #don't want to stop all processing so just note the problem and carry on
              logger.error Time.now.to_s + " : Problem with processing of " + dataset + " : " + e
            end
            end
          end
        end
      
      # email_user
    rescue Exception => e     
      logger.error "Problem processing nesstar catalogs " + e
      # send an error message
      # Mailer.deliver_nesstar_catalogs_processing_error(dataset, user_id, e, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
      
    end
    end
    # TODO - surveys need to belong to a user.  datasets need to belong to a user.
    # can different people add datasets to a survey - permissions issue?
    # tell the user that the dataset has been processed. 
    def email_user
      # Mailer.deliver_nesstar_catalogs_processed(datasets, user_id, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
    end

end
end