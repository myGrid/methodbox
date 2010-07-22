#Use for loading xml based metadata for a dataset.  Can be used to reload metadata file
#even if the database already has variables for that survey.  Change the survey_id to
#match the appropriate year and the parser to load the correct xml file

require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'xml'

namespace :obesity do
  desc "load metadata from xml"
  task :read_ccsr_metadata  => :environment do
    parser = XML::Parser.file('/Users/Ian/scratch/ccsr_metadata_xml/lf1997.xml', :encoding => XML::Encoding::ISO_8859_1)
    doc = parser.parse

      nodes = doc.find('//ccsrmetadata/variables')
      # doc.close

      nodes[0].each_element do |node|
        if (/^id_/.match(node.name)) 
          name = node["variable_name"]
          label = node["variable_label"]
          puts name + " " + label
          node.each_element do |child_node| 
            if (!child_node.empty?) 
              puts  "value " + child_node["value"] + " label " + child_node["value_name"]
            end
          end
          end
        end
        
        # variable = Variable.new
        #          variable.name = name
        #          variable.value= label
        #          variable.dertype = variable_dertype
        #          variable.dermethod = variable_dermethod
        #          variable.info = variable_info
        #          variable.category = variable_category
        #          variable.dataset_id = dataset_id;
        #          variable.page = page
        #          variable.document = document
        #          variable.save


    end
  end
