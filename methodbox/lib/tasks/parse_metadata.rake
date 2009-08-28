require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'xml'

namespace :obesity do
  desc "load metadata from xml"
  task :load_metadata  => :environment do
    parser = XML::Parser.file('/Users/Ian/obesity_data/2007/descxml.xml')
    doc = parser.parse

    nodes = doc.find('//metadata/variable')

    nodes.each do |node|
      variable = Variable.new
      namenode = node.find('child::name')
      namecontent = namenode.first.content
      print namecontent
      variable.name = namecontent

      descnode = node.find('child::description')
      desccontent = descnode.first.content
      print desccontent
      variable.value = desccontent

      variable.survey_id = 8;

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
