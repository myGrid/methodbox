# Value domains pulled from ccsr metadata were recorded twice

require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'

namespace :obesity do
  desc "fix value domains pulled from ccsr metadata"
  task :fix_ccsr_value_domain  => :environment do
    Variable.all.each do |variable|
      if variable.info != nil && !variable.info.include?("SPSS")
        value_domains = variable.value_domains
        if !value_domains.empty?
          info = String.new
          value_domains.each do |value_domain|
            info << "value " + value_domain.value + " label " + value_domain.label + "\r\n"
          end
          variable.update_attributes(:info => info)
          puts "update for " + variable.name + variable.dataset.name
        end
      end
    end
  end
end