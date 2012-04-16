= Background 

Obesity is one of the leading causes of preventable death world-wide, and a priority for many governments. It is caused when we consume more energy than what is spent in physical activity. Mostly this can be related to social factors; however studies of these factors, usually only relate to one side of the energy balance equation. In order to readdress this, there is a need for easily-shared, multi-disciplinary social research into obesity.

The team is developing an eLab - a unique, secure environment for producing, sharing and communicating research between epidemiologists, public health researchers and social scientists.

The project has developed and deployed the data sharing platform methodbox. MethodBox aims to provide a simple, easy to use environment for browsing and sharing surveys, methods and data. Variables (ie columns in spreadsheet/csv data) can be searched for using keywords. Metadata for the variables can be viewed and the variables themselves can be added to your cart and downloaded. MethodBox is a generic Ruby on Rails based web application that can be seeded with any type of csv style datasets. It's original intention was to support health researchers involved in obesity data investigations with emphasis on datasets from the UK Data Archive.

The project is developed by the myGrid team at the University of Manchester, funded by the Economic & Social Research Council and comes under the Digital Social Research umbrella with additonal help and advice from the Economic and Social Data Service and Cathy Marsh Centre for Social Research. 

= Overview

MethodBox is a Ruby on Rails 2.3.x (tested up to rails 2.3.14 and ruby 1.8.7) application designed for the storage, finding and sharing of tabular and csv data.  User can upload survey data, search for columns, download only the columns they require in various formats, make comments and add methods which can be linked to the data.

= Architecture

The main application is a Ruby on Rails 2.3.x application which has been tested on WEBrick and Apache with Passenger Phusion (tested up to version 3.0.1).
Apache SOLR is used through the sunspot plugin http://outoftime.github.com/sunspot/
Delayed Job (https://github.com/collectiveidea/delayed_job/tree/v2.0) is used to process the data files in the background.

= Rails setup

config/environment_local.example.rb contains various constants which are used eg. to point the delayed job tasks to the correct folder for data storage.  Copy file to config/initializers/environment_local.rb and then make the changes.  There are a few redundant contstants in this file and we are in the process of removing them.
config/environment.example.rb includes set up for the exception handler and needs your email address so it can send any bug reports to the correct address.  Copy file to environment.rb and then make the changes
config/environments/RAILS_ENV.example.rb (eg production.rb) need email details that MethodBox uses to send out notifications.  It also has a STATISTICS_ROUTE which is an obfuscated url that you can use to give to someone interested in the download stats.  In these file there is a constant called ROUTES_PROTOCOL which can be set to 'http' or 'https' and is used by the config/routes.rb file to make certain routes over 'https' if you require (don't forget certificates for apache etc, hard to test in development).  Copy file to eg. development.rb and then make the changes.

MethodBox uses bundler to handle its gems.  (sudo) gem install bundler to install it and then bundle install in the MethodBox root to install the gems in the application. 
When installing these gems you may also have to install some native libraries, the following list is for gnu/linux:
libxml2
libxml2-dev
libxslt
libxslt-dev
imagemagick
libmagick9-dev
sqlite
libsqlite3-dev
openssl-devel
unixodbc-dev (required for ruby-odbc)

You may also have to build the ruby openssl support.  If you built from source then go to RUBY_SOURCE_DIR/ext/openssl, or try the RUBY_INSTALL_DIR/ext/openssl and run
ruby extconf.rb
make
make install

or from packages on debian/ubuntu etc sudo apt-get install libopenssl-ruby1.8

If setting up the database using migrations you will also need to run 
> rake savage_beast:bootstrap_db 
to set up the tables for the savage beasts forum plugin.

= SOLR setup

MethodBox uses the Sunspot plugin to drive SOLR (http://outoftime.github.com/sunspot/).  By default the config and index will be saved in the rails root in a directory called 'solr'. If you want it to store things in a different place then copy the config/sunspot_example.yml to config/sunspot.yml and change the file paths inside it to the correct places.  Start solr with rake sunspot:solr:start, for production add "RAILS_ENV=production" to the end.  To stop use rake sunspot:solr:stop and to reindex use rake sunspot:reindex. You could also install it in tomcat, see http://wiki.apache.org/solr/SolrTomcat. It seems to work better adding the solr-home parameter to the appropriate place in the tomcat/webapps/solr/WEB-INF/web.xml . You will also need to copy the conf files from the sunspot gems conf directory and add to the solr conf directory.
Note that on windows the rake sunspot:solr:start task does not work since windows does not support the fork() directive, use rake sunspot:solr:run instead or install in a servlet container like tomcat

= Delayed job setup

Uses the delayed job ruby gem from the 2.0 branch (2.1 is only for rails 3+). Change the constants in the environment_local.rb file as noted in Rails setup above and run the command appropriate to the environment (in production mode you are recommended to run it as a background daemon process):
Development: 
> rake jobs:work
Production 
> RAILS_ENV=production script/delayed_job -n 2 
the number after n is the amount of workers you want to start.  You can also start it in dev mode this way with script/delayed_job start instead of the rake task. Note that the environment info comes at the start and is not quoted.
To stop it use RAILS_ENV=production script/delayed_job stop
We found that using the delayed_job gem with daemons gem higher than 1.0.10 caused unpredictable behaviour when starting workers so we lock that in the bundle Gemfile. 
On windows script/delayed_job does not work so use rake jobs:work instead with one command terminal for each worker.

= To HTTPS or not HTTPS

The protocol (ie http or https) for the routes is set by the constant ROUTES_PROTOCOL in your development/procuction/test.rb file.  All the routes in routes.rb will be set to use this protocol. You should also set the HTTPS_ON boolean constant in environment_local.rb to be true or false depending on whether you want the routes to require ssl or not.  By setting the HTTPS_ON to false and ROUTES_PROTOCOL to http then you can run http routes when developing (or in production if you do not want ssl). In the controllers it uses the ssl_requirement plugin and overrides the ssl_required? method to return whatever you put in the HTTPS_ON constant via a method in the ApplicationController.

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
MethodBox was designed to be used with UK Data Archive data run by the Economic and Social Data Service.  As such it checks user email addresses against their registered user list when users try to download UKDA data, if they are not registered with them then it does not allow them to download.  Users can also login using Shibboleth and the UK Federation authorisation service.

= Configuring survey names for UI display

The names for survey type, survey and dataset are configurable within the views by defining the constants SURVEY_TYPE, SURVEY and DATASET.  There is an example in config/initializers/survey_names.rb_example.  Move this to survey_names.rb and change the names to be whatever you want.

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

=Developers
Code has been contributed by the following people:

Ian Dunlop
Shoaib Sufi
Christian Brenninkmeijer
Rob Haines
Sam Smith

=Licence
The MethodBox software developed by the University of Manchester uses the New BSD License.  Other software (eg plugins) developed by other authors but used by MethodBox may use different but compatible licences, please see the individual bits of software for further information.

Copyright 2008-2012 University of Manchester
