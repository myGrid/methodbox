require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'xml'

namespace :obesity do
  desc "load metadata from xml"
  task :load_metadata  => :environment do
    parser = XML::Parser.file('/Users/Ian/downloads/metadata-HSE-2006-v3a.xml')
    doc = parser.parse

    nodes = doc.find('//metadata/variable')

    nodes.each do |node|
      variable = Variable.new
      namenode = node.find('child::name')
      namecontent = namenode.first.content
      print "NAME: " + namecontent
      variable.name = namecontent

      descnode = node.find('child::description')
      desccontent = descnode.first.content
      print "DESC: " + desccontent
      variable.value = desccontent
      
       catnode = node.find('child::category')
        catcontent = catnode.first.content
        print "CAT: " + catcontent
        variable.category = catcontent
        
      dernode = node.find('child::derivation')
      dercontent = dernode.first
      
      dertype = dercontent.find('child::type')
      dertypecontent = dertype.first.content
      variable.dertype = dertypecontent
      print "TYPE: " + dertypecontent
      
      dermethod = dercontent.find('child::method')
      if dermethod.first != nil
      dermethodcontent = dermethod.first.content
      variable.dermethod = dermethodcontent
      print "METHOD: " + dermethodcontent
    else
      print "METHOD: NIL"
    end
      
      infonode = node.find('child::information')
      infocontent = infonode.first.content
      variable.info = infocontent
      print "INFO: " + infocontent
      
      variable.survey_id = 7;
      
      variable.save
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
