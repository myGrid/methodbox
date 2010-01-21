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
  task :load_metadata  => :environment do
    parser = XML::Parser.file('/Users/Ian/scratch/HSE2006-01-21.xml')
    doc = parser.parse
    survey_id = 7
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
        print "METHOD: " + dermethodcontent
      else
        print "METHOD: NIL"
      end
      
      infonode = node.find('child::information')
      infocontent = infonode.first.content
      variable_info = infocontent
      print "INFO: " + infocontent


      
      v = Variable.find(:all,:conditions=> "survey_id=" + survey_id.to_s + " and name='" + variable_name+"'")
      if (v[0]!= nil)
        puts "Found Variable " + v[0].name
#        v[0].value= variable_value
#        v[0].dertype = variable_dertype
#        v[0].dermethod = variable_dermethod
#        v[0].info = variable_info
#        v[0].category = variable_category
#        v[0].save
        if v[0].update_attributes(:value=>variable_value, :dertype=>variable_dertype, :dermethod=>variable_dermethod, :info=>variable_info,:category=>variable_category)
          puts "Update success"
        else
          v[0].errors.full_messages.to_sentence
        end

      else
        puts "New Variable"
        variable = Variable.new
        variable.name = variable_name
        variable.value= variable_value
        variable.dertype = variable_dertype
        variable.dermethod = variable_dermethod
        variable.info = variable_info
        variable.category = variable_category
        variable.survey_id = survey_id;
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
    end
  end

end
