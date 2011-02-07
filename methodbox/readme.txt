= Overview

MethodBox is a Ruby on Rails 2.3.x (tested up to rails 2.3.5 and ruby 1.8.7) application designed for the storage, finding and sharing of tabular and csv data.  User can upload survey data, search for columns, download only the columns they require in various formats, make comments and add methods which can be applied to the data.

= Architecture

The main application is a Ruby on Rails 2.3.x application which has been tested on WEBrick and Apache with Passenger Phusion (tested up to version 3.0.1).
Apache SOLR is used through the acts_as_solr plugin.  It is no longer supported however and we may move to something like Sunspot in the future.
Delayed Job (https://github.com/tobi/delayed_job) is used to process the data files in the background.

= Rails setup

config/environment_local.example.rb contains various constants which are used eg. to point the delayed job tasks to the correct folder for data storage.  Copy file to environment_local.rb and then make the changes.  There are a few redundant contstants in this file and we are in the process of removing them.
config/environment.example.rb includes set up for the exception handler and needs your email address so it can send any bug reports to the correct address.  Copy file to environment.rb and then make the changes
config/environments/RAILS_ENV.example.rb (eg production.rb) need email details that MethodBox uses to send out notifications.  It also has a STATISTICS_ROUTE which is an obfuscated url that you can use to give to someone interested in the download stats.  In these file there is a constant called ROUTES_PROTOCOL which can be set to 'http' or 'https' and is used by the config/routes.rb file to make certain routes over 'https' if you require (don't forget certificates for apache etc, hard to test in development).  Copy file to eg. development.rb and then make the changes.
MethodBox uses bundler to handle its gems.  (sudo) gem install bundler to install it and then bundle install in the MethodBox root to install the gems in the application. 
If setting up the database using migrations you will also need to run 
> rake savage_beast:bootstrap_db 
to set up the tables for the savage beasts forum plugin.

= SOLR setup

Set SOLR_ENABLED to true in the appropriate environment file.  vendor/plugins/acts_as_solr/solr_environment.example.rb needs SOLR_DATA_PATH changed to point to where SOLR should store its data and saved as solr_environment.rb. Don't forget to run the SOLR server with rake solr:start and stop with rake solr:stop.  SOLR sometimes complains when starting that certain directories or pid files are missing, just create the directories as necessary.  Note that when SOLR bails out this way then you cannot stop with rake solr:stop but it will still have used port 8983.  Use lsof -i:8983 or similar to find the process number and kill it off. In production mode don't forget to start it using rake solr:start "RAILS_ENV=production"

= Delayed job setup

Change the constants in the environment_local.rb file as noted in Rails setup above and run the command appropriate to the environment (in production mode you are recommended to run it as a background daemon process):
Development: 
> rake jobs:work
Production 
> script/server start

= Data

The following models are indexed by SOLR:
*Survey (ie. datasets that are added by users)
*Variable (columns from the datasets)
*Person (the is really a profile that belongs to a User)
*Script (usually referred to as methods & scripts, can be anything that users upload)
*Csvarchive (usually referred to as a data extract ie a cut down dataset)
*Publication (from pubmed or a DOI)

When a dataset (CSV or tab delimitted with headers) is uploaded by a user the process_dataset_job.rb delayed job (in lib) gives it a unique id and then splits it up into one file for each column and does some basic stats on the columns.
When a user adds variables (ie columns) to their cart and creates a data extract the data_extract_job.rb delayed job adds the columns together, creates any scripts needed for stata or SPSS stats package (the user chooses this at download time), generates a text file with the metadata about the variables and zips them all up.
MethodBox was designed to be used with UK Data Archive data run by the Economic and Social Data Service.  As such it checks user email addresses against their registered user list when users try to download UKDA data, if they are not registered with them then it does not allow them to download.  We are currently investigating the use of Shibboleth to use the UK Federation authorisation service.

= Metadata

Once a dataset has been added a User can also upload metadata about it.  There are 2 formats that MethodBox currently accepts, one that we developed internally and one from the social science people at CCSR at Manchester University.  The format was designed to match the metadata available for the Health Survey for England but is generic enough to apply to most other datasets we have encountered so far.

*MethodBox format
<metadata>
  <variable>
    <name>DNOFT</name>
    <description>Frequency drank any alcoholic drink last 12 mths</description>
    <category>Adults General</category>
    <derivation>
      <type>Indiv/SC YP</type>
    </derivation>
    <information>This variable is  numeric, the SPSS measurement level is scale.
SPSS user missing values = -999 thru -1
	Value label information for dnoft
	Value = 1	Label = Almost every day
	Value = 2	Label = Five or six days a week
	Value = 3	Label = Three or four days a week
	Value = 4	Label = Once or twice a week
	Value = 5	Label = Once or twice a month
	Value = 6	Label = Once every couple of months
	Value = 7	Label = Once or twice a year
	Value = 8	Label = Not at all in the last 12 months
</information>
  </variable>
  </variable>
  <variable>
    <name>KETSALTA</name>
    <description>How important - limiting salt - adults?</description>
    <category>Adult Knowledge and Attitudes</category>
    <derivation>
      <type>SC 16yrs+</type>
	  <method>Some derivation method</method>
    </derivation>
    <information>This variable is  numeric, the SPSS measurement level is scale.
SPSS user missing values = -999 thru -1
	Value label information for ketsalta
	Value = -9	Label = Not answered (9)
	Value = -1	Label = Item not applicable
	Value = 1	Label = Very important
	Value = 2	Label = Quite important
	Value = 3	Label = Not very important
	Value = 4	Label = Not at all important
</information>
  </variable>
</metadata>

There is a richer set of metadata in the MethodBox format although the information node (or values or value domains depending on what you want to call them) doesn't split them up into key value pairs like the ccsr format. 

*CCSR metadata format

<ccsrmetadata>
	<variables variable_label="11th heart rate measurement (330secs)" variable_name="hr11">
		<values value="-1.00" value_name="Item not applicable"/>
		<values value="-7.00" value_name="Refused/not obtained"/>
	</variables>
	<variables variable_label="(D) Hypertensive categories:140/90: all  prescribed drugs for BP (Dinamap readings)" variable_name="hy140di">
   		<values value="-1.00" value_name="Item not applicable"/>
   		<values value="-7.00" value_name="Refused/not obtained"/>
	</variables>
</ccsrmetadata>

You can also load metadata by using the rake task lib/tasks/parse_metadata.rake or read_ccsr_metadata.rake assuming that your files are in the xml format that the parser expects.

When using this rake task you must ensure that you change the path where it loads the metadata from and also the id of the dataset so that each 'variable' is saved with the correct dataset id.  

= Email & user registration setup

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
MethodBox uses the restful_authentication plugin. We are currently investigating the use of Shibboleth to use the UK Federation authorisation service and may have multiple routes for user authentication in the future.

=Licence
The MethodBox software developed by the University of Manchester uses the New BSD License.  Other software (eg plugins) developed by other authors but used by MethodBox may use different but compatible licences, please see the individual bits of software for further information.