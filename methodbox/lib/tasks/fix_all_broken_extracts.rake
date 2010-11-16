# find any data extracts which have not completed. ie they are broken and
# recreate them

require 'rubygems'
require 'rake'

namespace :obesity do
  
  desc "fix any extracts which have failed to create"
  task :fix_broken_extracts  => :environment do
    #Find all existing People, copy their email to their User accounts
    Csvarchive.all.each do |extract|
      if !extract.complete
        puts "creating extract " + extract.filename + ", id " + extract.id.to_s
        variable_hash = Hash.new
        extract.variables.each do |variable|
          if (!variable_hash.has_key?(variable.dataset_id))
            variable_hash[variable.dataset_id] = Array.new
          end
          variable_hash[variable.dataset_id].push(variable.id)
        end
        begin 
          Delayed::Job.enqueue DataExtractJob::StartJobTask.new(variable_hash, extract.user_id, extract.id, extract.filename, false)
        rescue Exception => e
          puts e
          logger.error(e)
        end
      end
    end
  end
end