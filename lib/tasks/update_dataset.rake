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
  task :update_single_metadata  => :environment do
    parser = XML::Parser.file('/Users/Ian/Downloads/hse/HSE-2000-hse00ai--2010-06-11.xml')
    doc = parser.parse
    #current version is set to the existing current version + 1 if its an update of a dataset or else leave it the same
    current_version = 2
    old_version = 1
    #if this  is an ESDS update to an existing dataset then new_version is true and a new variable will be created, the current_version
    #should also be upped.  note that the dataset current_version should also be changed
    new_version = true
    # survey_id = 17
    dataset_id = 20
    # survey = Survey.find(survey_id)
    dataset = Dataset.find(dataset_id)
    missing_vars = []
    # datasets = survey.datasets
    # datasets.each do |dataset|
      puts "DATASET: " + dataset.name
      # dataset_id=dataset.id
      nodes = doc.find('//metadata/variable')

      nodes.each do |node|
      
        namenode = node.find('child::name')
        namecontent = namenode.first.content
                print " NAME: " + namecontent

        variable_name = namecontent

        descnode = node.find('child::description')
        desccontent = descnode.first.content
                print " DESC: " + desccontent
        variable_value = desccontent
      
        catnode = node.find('child::category')
        catcontent = catnode.first.content
                print " CAT: " + catcontent
        variable_category = catcontent
        
        dernode = node.find('child::derivation')
        dercontent = dernode.first
      
        dertype = dercontent.find('child::type')
        if dertype.first != nil
          dertypecontent = dertype.first.content
          variable_dertype = dertypecontent
                    print " TYPE: " + dertypecontent
        else
                    print "TYPE: NIL"
        end
      
        dermethod = dercontent.find('child::method')
        if dermethod.first != nil
          dermethodcontent = dermethod.first.content
          variable_dermethod = dermethodcontent

          page = dermethod[0].[]("page")

          document = dermethod[0].[]("document")

                    print "METHOD: " + dermethodcontent
          if page != nil
                         print " page: " + page + " document: " + document
          end
        else
                    print "METHOD: NIL"
        end
      
        infonode = node.find('child::information')
        infocontent = infonode.first.content
        variable_info = infocontent
                print "INFO: " + infocontent


        if !new_version
          v = Variable.find(:all,:conditions=> "dataset_id=" + dataset_id.to_s + " and name='" + variable_name+"'")
          if (v[0]!= nil)
            puts "Found Variable " + v[0].name

            if v[0].update_attributes(:value=>variable_value, :dertype=>variable_dertype, :dermethod=>variable_dermethod, :info=>variable_info,:category=>variable_category, :page=>page, :document=>document)
              puts "Update success"
            else
              v[0].errors.full_messages.to_sentence
            end

          else
            puts "Could not find " + variable_name + " in " + dataset.name
            
          end
        else
          puts "updating variable " + variable_name
          old_variable = Variable.find(:all,:conditions=> "dataset_id=" + dataset_id.to_s + " and name='" + variable_name+"' and current_version=" + old_version.to_s)
          if old_variable.empty?
            puts "could not find " + variable_name + " in existing database"
            missing_vars.push(variable_name)
          end
          v = Variable.new
          v.name = variable_name
          v.dataset_id = dataset.id
          v.value= variable_value
          v.dertype = variable_dertype
          v.dermethod = variable_dermethod
          v.info = variable_info
          v.category = variable_category
          v.page = page
          v.document = document
          v.current_version = current_version
          v.save
        end

      end
      if new_version
        puts "setting " + dataset.name + " to version " + current_version.to_s 
        dataset.current_version = current_version
        dataset.save
        puts "missing variables"
        missing_vars.each {|missing_var| puts missing_var}
      end
    end
end
