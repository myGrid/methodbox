require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'xml'
require 'ddi-parser'

namespace :obesity do
  desc "load metadata from xml"
  task :ccsr_parser  => :environment do
        dataset_id=478
        parser = DDI::Parser.new
        info = parser.parse('/home/ian/scratch/hse_2009_ddi.xml')
        info.ddi_variables.each do |var|
          name = var.name
          category = var.group
          variables = Variable.all(:conditions=>{:dataset_id=>dataset_id, :name=>name})
          variables.first.update_attributes(:category=>category) unless variables.empty?
        end
end
end
