#where should completed data extracts be stored
CSV_OUTPUT_DIRECTORY = "/Users/you/data/#{ENV['RAILS_ENV']}/complete"
#is the server running ssl routes or not
HTTPS_ON = true
#you need this so it doesn't do eg localhost:3000:3001 in ssl paths and redirects to correct port from https to http
#(is this needed when running in eg apache - no idea)
DEVELOPMENT_HTTPS = true
#no longer used
HOST_FOR_SECURE = 'localhost'
#only needed for development purposes but will need to switch to 443 or maybe have helper method
HTTPS_PORT = '3001'
#which version to write into the stata do files for the data extracts
STATA_VERSION = '10.0'
#Exception Notification - true to ignore errors if running on localhost
LOCAL_REQUEST_ERROR = true
ADMIN_CAN_SEE_DORMANT = true
#used by the doi publication stuff.  You need to register an address at http://www.crossref.org/requestaccount/ to do the DOI checking
ADMIN_EMAIL = "you@somewhere.com"
#switch on the sandbox ui warning messages
SANDBOX = false
#should emails be sent out when data extracts completed etc
EMAIL_ENABLED = true
#used for the rake metadata import task
METADATA_PATH='/Users/you/obesity_data/metadata/'
#the address used to check the users email against the ukda's registered users list
UKDA_EMAIL_ADDRESS='http://oai.esds.ac.uk:8080/NesstarLogin/login.do'
#these are no longer used since the data extract creation runs 'inside' the rails app with delayed job, only here for legacy code until cleaned up
CSV_SERVER_LOCATION='localhost'
CSV_SERVER_PORT='25000'
CSV_SERVER_PATH='/server/eos'
# CSV_SERVER_PATH='/eos'
CSV_FILE_PATH="/Users/you/obesity_data/#{ENV['RAILS_ENV']}/csv/"
#can users register themselves
REGISTRATION_CLOSED = true
NEW_CSV_FILE_PATH="/Users/you/obesity_data/#{ENV['RAILS_ENV']}/csv/complete"

