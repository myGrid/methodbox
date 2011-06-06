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
          hash = Hash.new
          value_domains.each do |value_domain|
            hash[value_domain.value] = value_domain.label
          end
          hash.sort.reverse.each do |value, label|
            info << "value " + value + " label " + label + "\r\n"
          end
          variable.update_attributes(:info => info)
          puts "update for " + variable.name + variable.dataset.name
        end
      end
    end
  end
end