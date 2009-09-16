The methodbox app requires metadata to be loaded into the apache solr server.  This can be achieved by using the rake task lib/tasks/parse_metadata.rake assuming that your files are in the xml format that the parser expects

<?xml version="1.0" encoding="UTF-8"?>
<metadata year="1991-1992">
	<variable>
		<name>wtresp</name>
		<description>Whether weight obtained (B sched)</description>
		<information>
			<info>
				<Value>1	</Value>
				<Label>refused</Label>
			</info>
			<info>
				<Value>2	</Value>
				<Label>not attempted</Label>
			</info>
			<info>
				<Value>3	</Value>
				<Label>obtained</Label>
			</info>
		</information>
		<MissingValues>-10  thru -6</MissingValues>
	</variable>
	<variable>
	...
	</variable>
</metadata>

When using this rake task you must ensure that you change the bit where it loads the metadata and also the id of the survey so that each 'variable' is saved with the correct survey id.  Make sure you do a rake db:migrate first to ensure that the default survey info is loaded in the database.

The app also uses a separate tool to handle csv parsing and serving of csv survey data.  This is in the csvserver module.  It needs some environment info placed in the /src/main/webapp/WEB-INF/classes/messages.properties file.  These are
DownloadFile.31=/Volumes/Data/datasets/complete/
RTFSearcher.0=/Volumes/Data/datasets/
SerializeMap.0=/Volumes/Data/datasets/

Basically, where it should save completed zip files to, where it should load any source csv tab survey data files from and where it should serialize its requests when processing the files (in case of server problems).

You can start this app in a tomcat container (although we have had some xml processing issues) or using jetty with mvn -Djetty.port=2500 jetty:run

Setting up email:

You need to set EMAIL_ENABLED=true in environment_local.rb and also set ACTIVATION_REQUIRED=true in the appropriate file in /environments.  If you want new users to join then set REGISTRATION_CLOSED=false in environment_local.  You then need to add the ActivationMailer config to the environment file 
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

SOLR setup:

Set SOLR_ENABLED to true in the appropriate environment file.  Don't forget to run the SOLR server with rake solr:start and stop with rake solr:stop.  SOLR sometimes complains when starting that certain directories or pid files are missing, just create the directories as necessary.  Note that when SOLR bails out this way then you cannot stop with rake solr:stop but it will still have nicked port 8983.  Use lsof -i:8983 or similar to find the process number and kill it off.
 
