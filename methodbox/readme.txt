The methodbox app requires metadata to be loaded into the apache solr server.  This can be achieved by using the rake task lib/tasks/parse_metadata.rake or read_ccsr_metadata.rake assuming that your files are in the xml format that the parser expects.  

When using this rake task you must ensure that you change the bit where it loads the metadata and also the id of the dataset so that each 'variable' is saved with the correct dataset id.  Make sure you do a rake db:migrate first to ensure that the default survey info is loaded in the database.  

You don't have to do this on the command line, the code is also set up for any csv survey type data.  You can load it by creating new survey types and surveys and adding datasets/metadata to them through the ui.

The app also uses a separate tool to handle csv parsing and serving of csv survey data.  This is in the csvserver module.  It needs some environment info placed in the /src/main/webapp/WEB-INF/classes/messages.properties file.  These are
DownloadFile.31=/Volumes/Data/datasets/complete/
RTFSearcher.0=/Volumes/Data/datasets/
SerializeMap.0=/Volumes/Data/datasets/

Basically, where it should save completed zip files to, where it should load any source csv tab survey data files from and where it should serialize its requests when processing the files (in case of server problems).

It also needs some info about the email address you want to send notifications from, email.properties.

You can start this app in a tomcat container (although we have had some xml processing issues) or using jetty with mvn -Djetty.port=2500 jetty:run

Setting up email:

On the rails side. You need to set EMAIL_ENABLED=true in environment_local.rb and also set ACTIVATION_REQUIRED=true in the appropriate file in /environments.  If you want new users to join then set REGISTRATION_CLOSED=false in environment_local.  You then need to add the ActivationMailer config to the environment file 
eg
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :domain => "mydomain.org",
  :authentication => :plain,
  :user_name => "me",
  :password => "password"
}
This setup is for TLS/SSL using gmail, it's a lot easier with non-authenticated SMTP.

There are a few other important variables in environment_local.rb.  You also need to tell rails whether to use the ssl/https routes or not, add the ROUTES_PROTOCOL variable in environments/production.rb development.rb etc to your protocol of choice (http or https).  This then sets the correct routes in routes.rb.

SOLR setup:

Set SOLR_ENABLED to true in the appropriate environment file.  Don't forget to run the SOLR server with rake solr:start and stop with rake solr:stop.  SOLR sometimes complains when starting that certain directories or pid files are missing, just create the directories as necessary.  Note that when SOLR bails out this way then you cannot stop with rake solr:stop but it will still have nicked port 8983.  Use lsof -i:8983 or similar to find the process number and kill it off.
 
Some handy tips:

If you want to set up your db for non development use then add RAILS_ENV="production" (or test) to the end of your rake db:migrate command
