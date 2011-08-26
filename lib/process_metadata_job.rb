# Use delayed job. Process metadata for a dataset

module ProcessMetadataJob
  
  class StartJobTask < Struct.new(:dataset_id, :user_id, :file_type, :filename, :update_reason, :base_host)
    
    
    cattr_accessor :logger
    self.logger = RAILS_DEFAULT_LOGGER
    
    def perform
      begin
      dataset = Dataset.find(dataset_id)
      logger.info "Updating metadata for " + dataset.name
      case file_type
      when "CCSR"
        read_ccsr_metadata
      when "Methodbox"
        read_methodbox_metadata
      end
      dataset.update_attributes(:has_metadata => true)
      email_user
    rescue Exception => e     
      logger.error "Problem processing dataset " + dataset.id.to_s + ", "  + e
      puts "Problem processing dataset " + dataset.id.to_s + ", "  + e
      # send an error message
      Mailer.deliver_metadata_processing_error(dataset_id, user_id, e, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
      
    end
    end
    # TODO - surveys need to belong to a user.  datasets need to belong to a user.
    # can different people add datasets to a survey - permissions issue?
    # tell the user that the dataset has been processed. 
    def email_user
      Mailer.deliver_metadata_processed(dataset_id, user_id, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
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

        @missing_variables=[]
        parser = XML::Parser.io(params[:file][:metadata], :encoding => XML::Encoding::ISO_8859_1)
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
              v[0].update_attributes(:value=>label, :info=>value_map,:updated_by=>current_user.id, :update_reason=>update_reason)

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

              v[0].update_attributes(:value=>label, :info=>value_map,:updated_by=>current_user.id, :update_reason=>update_reason)

            # don't care about 'false positives' in the metadata, all we care about is the columns from the original dataset
            end 
      end
    end
    end

end
end
