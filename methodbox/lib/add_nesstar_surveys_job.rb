# Use delayed job. Add surveys from a nesstar catalogue that a user has selected

require 'nesstar-api'

module AddNesstarSurveysJob
  
  class StartJobTask < Struct.new(:datasets, :nesstar_url, :nesstar_catalog, :groups, :sharing_scope, :user_id, :base_host)
    
    
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
                  logger.info Time.now.to_s + " : retrieving info for " + dataset + ", " + dataset_info.title + ", with parent " + survey + ", and survey type " + survey_type
                  
                  study = n.get_study_information nesstar_url, dataset
                  
                  #TODO - pass in ukda status
                  #find exisitng survey type or create new one
                  if survey_type_info != nil
                    catalog_survey_types = SurveyType.all(:conditions=>{:name => survey_type_info.label})
                    if catalog_survey_types.empty?
                      catalog_survey_type = SurveyType.new(:name => survey_type_info.label, :nesstar_id => survey_type, :nesstar_uri => nesstar_url)
                      #create a new forum for the catalog
                      forum = Forum.new()
                      forum.name = catalog_survey_type.name
                      forum.description = "Questions about " + catalog_survey_type.name
                      forum.position = 4
                      forum.save

                      catalog_survey_type.save
                      if survey_type_info.description != nil
                          catalog_survey_type.update_attributes(:description => survey_type_info.description.gsub(/<\/?[^>]*>/, ""))
                      end
                    else
                      catalog_survey_type = catalog_survey_types[0]
                    end
                  else
                    catalog_survey_types = SurveyType.all(:conditions=>{:name => "none"})
                    if catalog_survey_types.size == 0
                      catalog_survey_type = SurveyType.new(:name => 'none', :description => 'Surveys which do not have a specified survey type')
                      catalog_survey_type.save
                      forum = Forum.new()
                      forum.name = "surveys with no parent catalog"
                      forum.description = "Questions about surveys with no parent catalog"
                      forum.position = 4
                      forum.save
                    else
                      catalog_survey_type = catalog_survey_types[0]
                    end
                  end
                  #find existing survey or create new one
                  catalog_surveys = Survey.all(:conditions => {:title => parent_info.label, :survey_type_id => catalog_survey_type.id})
                  if catalog_surveys.empty?
                    catalog_survey = Survey.new(:title => parent_info.label, :survey_type_id => catalog_survey_type.id, :year => 'N/A', :source => 'nesstar', :nesstar_id => parent_info.nesstar_id, :nesstar_uri => parent_info.nesstar_uri)
                    catalog_survey.save
                    if parent_info.description != nil
                        catalog_survey.update_attributes(:description => parent_info.description.gsub(/<\/?[^>]*>/, ""))
                    end
                    #TODO user can define policy when adding the surveys
                    
                    policy = Policy.create(:name => "survey_policy", :sharing_scope => sharing_scope, :use_custom_sharing => sharing_scope == Policy::CUSTOM_PERMISSIONS_ONLY.to_s ? true : false, :access_type => 2, :contributor => User.find(user_id))
                    if groups != nil && sharing_scope == Policy::CUSTOM_PERMISSIONS_ONLY.to_s
                       groups.each do |workgroup_id|
                          policy.permissions << Permission.create(:contributor_id => workgroup_id, :contributor_type => "WorkGroup", :policy => policy, :access_type => 2)
                        end
                    end
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
                    catalog_dataset = Dataset.new(:current_version => 1, :filename => study.variables[0].file, :name => study.title, :survey => catalog_survey, :nesstar_id => study.nesstar_id, :nesstar_uri => study.nesstar_uri)
                    catalog_dataset.save
                    if study.abstract != nil
                        catalog_dataset.update_attributes(:description => study.abstract.gsub(/<\/?[^>]*>/, ""))
                    end
                  else
                    #this should be a new dataset so throw exception and carry on to the next
                    raise 'This dataset has already been added'
                  end
                  #create variables for the dataset
                  study.variables.each do |variable|
                    var = Variable.new(:name=> variable.name, :value => variable.label, :category => variable.group, :interval => variable.interval, :dataset => catalog_dataset, :nesstar_id => variable.id, :nesstar_file => variable.file, :max_value => variable.max, :min_value => variable.min)
                    logger.info Time.now.to_s + " : saving variable " + variable.name + " from " + study.title
                    var.save
                    variable.categories.each do |category|
                      valDom = ValueDomain.new(:variable => var, :value => category.value, :label => category.label)
                      valDom.save
                      category.category_statistics.each do |statistic|
                      #the frequency statistics for the value domain
                      #guessing that 'freq' is consistent, however......
                        if statistic.type == 'freq'
                          val_dom_stat = ValueDomainStatistic.new(:frequency => statistic.value, :value_domain => valDom)
                          val_dom_stat.save
                          break
                        end
                        
                      end
                    end
                    variable.summary_stats.each do |summary_stat|
                      begin
                      if summary_stat.type == 'mean'
                        var.update_attributes(:mean => summary_stat.value)
                      elsif summary_stat.type == 'stdev'
                        var.update_attributes(:standard_deviation => summary_stat.value)
                      elsif summary_stat.type == 'invd'
                        var.update_attributes(:invalid_entries => summary_stat.value)
                      elsif summary_stat.type == 'vald'
                        var.update_attributes(:valid_entries => summary_stat.value)
                      end
                    rescue
                      logger.warn Time.now.to_s + 'One of the summary stats failed for variable ' +  var.id.to_s
                    end
                    end
                    question = variable.question != nil ? variable.question : ""
                    interview = variable.interview_instruction != nil ? variable.interview_instruction : ""
                    derivation = question + interview
                    if variable.question != nil && variable.interview_instruction != nil
                      var.update_attributes(:dermethod => derivation)
                    end
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
      
      email_user
    rescue Exception => e     
      logger.error Time.now.to_s + "Problem processing nesstar catalogs " + e
      # send an error message
      Mailer.deliver_nesstar_catalogs_processing_error(dataset, user_id, e, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
      
    end
    end
    # TODO - surveys need to belong to a user.  datasets need to belong to a user.
    # can different people add datasets to a survey - permissions issue?
    # tell the user that the dataset has been processed. 
    def email_user
      Mailer.deliver_nesstar_catalogs_processed(datasets, user_id, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
    end

end
end