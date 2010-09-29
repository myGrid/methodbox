#Add the existing emails which People have to their User accounts. The latest
#code uses the email as the login id

require 'rubygems'
require 'rake'

namespace :obesity do
  desc "load data from csv"
  task :create_delayed_job_extracts  => :environment do
    Csvarchive.all do |archive|
      variable_hash = Hash.new
      archive.variables.each do |variable|
        if (!variable_hash.has_key?(variable.dataset_id))
          variable_hash[variable.dataset_id] = Array.new
        end
        variable_hash[variable.dataset_id].push(item.variable_id)
      end
      Delayed::Job.enqueue DataExtractJob::StartJobTask.new(variable_hash, archive.user.id, archive.id, archive.filename)
    end
  end
end