require 'rake'

namespace :obesity do
  desc "create ten thousand users"
  task :create_thousands_of_users  => :environment do
    for i in 0..10000
      puts i.to_s
      email_address = Faker::Internet.email
      password = UUIDTools::UUID.random_create.to_s
      person = Person.new(:first_name=>Faker::Name.first_name, :last_name=>Faker::Name.last_name, :email=>email_address)
      begin
        person.save
      rescue Exception=>e
        puts e
        puts "person save probably just a non unique email"
      end
      user = User.new(:email=>email_address, :password=>password, :password_confirmation=>password)
      user.person = person
      puts user.email + " " + user.password + " " + user.password_confirmation
      puts person.first_name + " " + person.last_name + " " + person.email
      begin
        user.save
        user.activate
      rescue Exception=>e
        puts e
        puts "user save probably just a non unique email"
      end
    end
  end
end
