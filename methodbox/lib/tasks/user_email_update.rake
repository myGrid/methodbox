#Add the existing emails which People have to their User accounts. The latest
#code uses the email as the login id

require 'rubygems'
require 'rake'

namespace :obesity do
  desc "load data from csv"
  task :update_email  => :environment do
    #Find all existing People, copy their email to their User accounts
    Person.find(:all).each do |person|
      person.user.email=person.email
      puts person.name + " has email " + person.email
      person.user.save
    end
  end
end