# find any data extracts which have not completed. ie they are broken and
# recreate them

require 'rubygems'
require 'rake'

namespace :obesity do
  
  desc "add dates to surveys based on a regex of their titles"
  task :add_dates_to_surveys => :environment do
    #match 4 consecutive digits, maybe not exhaustive but it will do
    re = Regexp.new('\d{4}\b')
    Survey.all(:conditions=>{:year=>'N/A'}).each do |survey|
      re.match(survey.title)
      if $& != nil
        puts "assigning year " + $& + " to survey " + survey.id.to_s + ", " + survey.title
        survey.update_attributes(:year=>$&)
      end
    end
  end
end
