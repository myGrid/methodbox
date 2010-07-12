#Loops through all the users and sends them an email

require 'rubygems'
require 'rake'
require 'send_gmail'

namespace :obesity do
  desc "send users an email"
  task :send_user_email  => :environment do
    #Find all existing People, copy their email to their User accounts
    
    email_hash = Hash.new
    email_hash[:subject] = "MethodBox server maintenance"
    email_hash[:body] = "Methodbox will be unavailable for one or two hours this afternoon (Monday 12 July) for esssential maintenance and upgrades. \nThank you for your patience while we carry out this work.\n\n The MethodBox team"
    User.find(:all).each do |user|
      email_hash[:to] = email=user.email
      SendGMail.send_gmail(email_hash)
    end

  end
end