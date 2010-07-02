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
  task :load_single_metadata  => :environment do
    parser = XML::Parser.file('/Users/Ian/Downloads/output/HSE-2001-hse01ai--2010-06-30.xml')
    doc = parser.parse
        missing_vars = []
    # survey_id = 17
    #    survey = Survey.find(survey_id)
    #    datasets = survey.datasets
    #    datasets.each do |dataset|
      #puts "DATASET: " + dataset.name
      dataset_id=22
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


      
        v = Variable.find(:all,:conditions=> "dataset_id=" + dataset_id.to_s + " and name='" + variable_name+"'")
        if (v[0]!= nil)
          puts "Found Variable " + v[0].name
          #        v[0].value= variable_value
          #        v[0].dertype = variable_dertype
          #        v[0].dermethod = variable_dermethod
          #        v[0].info = variable_info
          #        v[0].category = variable_category
          #        v[0].save
          if v[0].update_attributes(:value=>variable_value, :dertype=>variable_dertype, :dermethod=>variable_dermethod, :info=>variable_info,:category=>variable_category, :page=>page, :document=>document)
            puts "Update success"
          else
            v[0].errors.full_messages.to_sentence
          end

        else
          missing_vars.push(variable_name)
          puts "Could not find " + variable_name
                 variable = Variable.new
                 variable.name = variable_name
                 variable.value= variable_value
                 variable.dertype = variable_dertype
                 variable.dermethod = variable_dermethod
                 variable.info = variable_info
                 variable.category = variable_category
                 variable.dataset_id = dataset_id;
                 variable.page = page
                 variable.document = document
                 variable.save
        end
      
      
     
        #  infonode = node.find('child::information')
        #  if infonode.length>=1
        #    infochildren = infonode[0].find('child::info')
        #    infochildren.each do |childnode|
        #      valnode = childnode.first
        #      valvalue = valnode.first.content
        #      labelnode = valnode.next
        #      labelvalue = labelnode.first.content
        #      print valvalue
        #      print labelvalue
        #    end
        #  end
      # end

    end
    puts "missing/new variables"
    missing_vars.each {|missing_var| puts missing_var}
  end

end
