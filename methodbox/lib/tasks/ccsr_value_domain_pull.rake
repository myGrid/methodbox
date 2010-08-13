#Read the value domains from a ccsr metadata file and populate the db
#There seem to be 2 different formats for these files, one where the variables are contained in a <variable> node
#and one where the node starts with <id_

require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'xml'

namespace :obesity do
  desc "load metadata from xml"
  task :read_ccsr_value_domain  => :environment do
    parser = XML::Parser.file('/Users/Ian/scratch/ccsr_metadata/hse1991.xml', :encoding => XML::Encoding::ISO_8859_1)
    dataset_id=1
    doc = parser.parse
    nodes = doc.find('//ccsrmetadata/variables')
    
    if nodes.size == 1
    nodes[0].each_element do |node|
      if (/^id_/.match(node.name)) 
        name = node["variable_name"]
        label = node["variable_label"]
        puts "FINDING " + name
        v = Variable.find(:all,:conditions=> {:dataset_id => dataset_id, :is_archived=>false, :name=>name})
        if (v[0]!= nil)
          puts "FOUND " + name
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
            valDom.save
            # value_map <<  "value " + child_node["value"] + " label " + child_node["value_name"] + "\r\n"
            puts "value " + child_node["value"] + " label " + child_node["value_name"]
          end
      end
      end
    end  
end
else
    nodes.each do |node|
      name = node["variable_name"]
      label = node["variable_label"]
              puts "FINDING " + name
      v = Variable.find(:all,:conditions=> {:dataset_id => dataset_id, :is_archived=>false, :name=>name})
      if (v[0]!= nil)
        puts "FOUND " + name
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
            valDom.save
            # value_map <<  "value " + child_node["value"] + " label " + child_node["value_name"] + "\r\n"
            puts "value " + child_node["value"] + " label " + child_node["value_name"]
          end
        end
      end 
    end
  end
end
end