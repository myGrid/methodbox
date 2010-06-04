#User searches now belong to a user rather than person.
#Run this task to update the db

require 'rubygems'
require 'rake'

namespace :obesity do
  desc "load data from csv"
  task :update_user_searches  => :environment do
    #Find all existing People, copy their email to their User accounts
    
    UserSearch.find(:all).each do |search|
      person = Person.find(search.user_id)
      search.user_id = person.user.id
      puts "Changing search " + search.id.to_s + " from " + person.name + " to user " + person.user.id.to_s
      search.save
    end
  end
end