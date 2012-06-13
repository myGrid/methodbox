# Use delayed job. Process metadata for a dataset

require 'ddi-parser'
require 'xml'

module ProcessMetadataJob
  
  class StartJobTask < Struct.new(:dataset_id, :user_id, :file_type, :filename, :update_reason, :base_host)
    
    
    cattr_accessor :logger
    self.logger = RAILS_DEFAULT_LOGGER
    @missing_variables=[]
    def perform
      begin
      dataset = Dataset.find(dataset_id)
      logger.info "Updating metadata for " + dataset.name
      case file_type
      when "CCSR"
        read_ccsr_metadata
      when "Methodbox"
        read_methodbox_metadata
      when "DDI"
        read_ddi_metadata
      end
      dataset.update_attributes(:has_metadata => true)
      email_user
    rescue Exception => e     
      logger.error Time.now.to_s + ", Problem processing metadata for dataset " + dataset.id.to_s + ", "  + e
      puts "Problem processing dataset " + dataset.id.to_s + ", "  + e
      # send an error message
      Mailer.deliver_metadata_processing_error(dataset_id, user_id, e, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
      
    end
    end
    # TODO - surveys need to belong to a user.  datasets need to belong to a user.
    # can different people add datasets to a survey - permissions issue?
    # tell the user that the dataset has been processed. 
    def email_user
      Mailer.deliver_metadata_processed(dataset_id, user_id, @missing_variables, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
    end
    
    #split the dataset into columns
      #Read the metadata from a methodbox internal formatted xml file for a particular survey
      def read_methodbox_metadata
        #don't think we need encoding here
        parser = XML::Parser.io(File.open(filename, "r"))
        doc = parser.parse

        nodes = doc.find('//metadata/variable')

        nodes.each do |node|

          namenode = node.find('child::name')
          namecontent = namenode.first.content

          variable_name = namecontent

          descnode = node.find('child::description')
          desccontent = descnode.first.content

          variable_value = desccontent

          catnode = node.find('child::category')
          catcontent = catnode.first.content

          variable_category = catcontent
          if variable_category == nil
            variable_category = 'N/A'
          end

          dernode = node.find('child::derivation')
          dercontent = dernode.first

          dertype = dercontent.find('child::type')
          if dertype.first != nil
            dertypecontent = dertype.first.content
            variable_dertype = dertypecontent
          else
          end

          dermethod = dercontent.find('child::method')
          if dermethod.first != nil
            dermethodcontent = dermethod.first.content
            variable_dermethod = dermethodcontent

            page = dermethod[0].[]("page")

            document = dermethod[0].[]("document")

            if page != nil
            end
          else
          end

          infonode = node.find('child::information')
          infocontent = infonode.first.content
          variable_info = infocontent
          v = Variable.find(:all,:conditions=> {:dataset_id => dataset_id, :is_archived=>false, :name=>variable_name})
          if (v[0]!= nil)
            v[0].update_attributes(:value=>variable_value, :dertype=>variable_dertype, :dermethod=>variable_dermethod, :info=>variable_info,:category=>variable_category, :page=>page, :document=>document, :update_reason=>update_reason)

            end
          end
      end

      #Read the metadata from a ccsr type xml file for a particular survey
      def read_ccsr_metadata

        parser = XML::Parser.io(File.open(filename, "r"), :encoding => XML::Encoding::ISO_8859_1)
        doc = parser.parse

          nodes = doc.find('//ccsrmetadata/variables')
          if nodes.size == 1
          nodes[0].each_element do |node|
            if (/^id_/.match(node.name)) 
              name = node["variable_name"]
              label = node["variable_label"]
              v = Variable.find(:all,:conditions=> {:dataset_id => dataset_id, :is_archived=>false, :name=>name})
              if (v[0]!= nil)
                v[0].value_domains.each do |valdom|
                  valdom.delete
                end
              value_map = String.new
              node.each_element do |child_node| 
                if (!child_node.empty?) 
                  valDom = ValueDomain.new
                  valDom.variable = v[0]
                  valDom.label = child_node["value_name"]
                  valDom.value = child_node["value"]
                  value_map <<  "value " + child_node["value"] + " label " + child_node["value_name"] + "\r\n"
                  valDom.save
                end
            end
              v[0].update_attributes(:value=>label, :info=>value_map,:updated_by=>user_id, :update_reason=>update_reason)

            # don't care about 'false positives' in the metadata, all we care about is the columns from the original dataset
            end
          end  
      end
    else
          nodes.each do |node|
              name = node["variable_name"]
              label = node["variable_label"]
              v = Variable.find(:all,:conditions=> {:dataset_id => dataset_id, :is_archived=>false, :name=>name})
              if (v[0]!= nil)
                v[0].value_domains.each do |valdom|
                  valdom.delete
                end
              value_map = String.new
              node.each_element do |child_node| 
                if (!child_node.empty?) 
                  valDom = ValueDomain.new
                  valDom.variable = v[0]
                  valDom.label = child_node["value_name"]
                  valDom.value = child_node["value"]
                  value_map <<  "value " + child_node["value"] + " label " + child_node["value_name"] + "\r\n"
                  valDom.save
                end
            end

              v[0].update_attributes(:value=>label, :info=>value_map,:updated_by=>user_id, :update_reason=>update_reason)

            # don't care about 'false positives' in the metadata, all we care about is the columns from the original dataset
            end 
      end
    end
    end

    #import ddi metadata for an existing dataset
    def read_ddi_metadata
      dataset = Dataset.find(dataset_id)
      logger.info '1'
      ddi_parser = DDI::Parser.new
      all_variables = Variable.all(:conditions=> {:dataset_id => dataset_id})
      all_variable_ids = all_variables.collect{|var| var.id}
      logger.info '2'
      parsed_variable_ids = []
      new_variables = []
      logger.info '2a'
      study = ddi_parser.parse filename
      logger.info '3'
      #create variables for the dataset
      study.ddi_variables.each do |variable|
        #TODO find the variable from the dataset and if nil then add new var since this is from nesstar and we don't use the dataset to find the vars
        existing_variable = Variable.all(:conditions=>{:name=>variable.name, :dataset_id => dataset_id}).first
        #if the variable does not exist then go on to the next one, only load metadata for vars in the db
        if existing_variable != nil
        if variable.group == nil
          variable_category = 'N/A'
        end
        logger.info '4'
        parsed_variable_ids << existing_variable.id         
        variable.categories.each do |category|
          valDom = ValueDomain.all(:conditions=>{:variable_id => existing_variable.id, :value => category.value, :label => category.label}).first   
          if valDom == nil 
            valDom = ValueDomain.new(:variable_id => existing_variable.id, :value => category.value, :label => category.label)
            valDom.save
          end     
          logger.info '5'
          category.category_statistics.each do |statistic|
          #the frequency statistics for the value domain
          #guessing that 'freq' is consistent, however......
            if statistic.type == 'freq'
              val_dom_stat = ValueDomainStatistic.all(:conditions=>{:frequency => statistic.value, :value_domain_id => valDom.id}).first
              if val_dom_stat == nil
                val_dom_stat = ValueDomainStatistic.new(:frequency => statistic.value, :value_domain_id => valDom.id)
                val_dom_stat.save
              else
                val_dom_stat.update_attributes(:frequency => statistic.value) if val_dom_stat.frequency != statistic.value
              end
              break
            end
          end
        end
        logger.info '6'
        variable.summary_stats.each do |summary_stat|
          begin
            if summary_stat.type == 'mean'
              existing_variable.update_attributes(:mean => summary_stat.value) if var.mean != summary_stat.value
            elsif summary_stat.type == 'stdev'
              existing_variable.update_attributes(:standard_deviation => summary_stat.value) if existing_variable.standard_deviation != summary_stat.value
            elsif summary_stat.type == 'invd'
              existing_variable.update_attributes(:invalid_entries => summary_stat.value) if existing_variable.invalid_entries != summary_stat.value
            elsif summary_stat.type == 'vald'
              existing_variable.update_attributes(:valid_entries => summary_stat.value) if existing_variable.valid_entries != summary_stat.value
            end
          rescue
            logger.warn Time.now.to_s + 'One of the summary stats failed for variable ' +  existing_variable.id.to_s
          end
        end
        question = variable.question != nil ? variable.question : ""
        interview = variable.interview_instruction != nil ? variable.interview_instruction : ""
        derivation = question + interview
        if variable.question != nil && variable.interview_instruction != nil
          existing_variable.update_attributes(:dermethod => derivation) if existing_variable.dermethod != derivation
        end
      end
      end
    end
  end
end
