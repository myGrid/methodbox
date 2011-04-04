# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.3' unless defined? RAILS_GEM_VERSION

#if you are running ruby gem 1.6 or higher you need this next line
#require 'thread'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

#if you get 'undefined local variable or method 'version_requirements' for #<Rails::GemDependency:gfsdgdg>' error
#if Gem::VERSION >= "1.3.6" 
#    module Rails
#        class GemDependency
#            def requirement
#                r = super
#                (r == Gem::Requirement.default) ? nil : r
#            end
#        end
#    end
#end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
#Used by savage beast forum plugin  
config.gem 'RedCloth'
  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug
  begin
    RAILS_DEFAULT_LOGGER = Logger.new("#{RAILS_ROOT}/log/#{RAILS_ENV}.log")
  rescue StandardError
    RAILS_DEFAULT_LOGGER = Logger.new(STDERR)
    RAILS_DEFAULT_LOGGER.level = Logger::WARN
    RAILS_DEFAULT_LOGGER.warn(
      "Rails Error: Unable to access log file. Please ensure that log/#{RAILS_ENV}.log exists and is chmod 0666. " +
        "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
    )
  end

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
      :session_key => '_method_box_session',
      :secret      => '1576ebcfekhjb234hkjhefg0j98273598273598237921cccc605a5abafc299ba87747jhvv9mmlll7c66537361f77'
    }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
#config.cache_classes = true #false


  
  # this will make the Authorization module available throughout the codebase
  require 'authorization'
  
  #seems to fix the "A copy of AuthenticatedSystem has been removed from the module tree but is still active" problem - http://yanpritzker.com/2008/02/27/rails-20-dependency-system-problems/
  #also need to set config.cache_classes = false in development.rb
  config.load_once_paths += %W( #{RAILS_ROOT}/lib )
  
end

require "will_paginate"

load 'config/environment_local.rb' if FileTest.exist?('config/environment_local.rb')

SOLR_ENABLED=false unless Object.const_defined?("SOLR_ENABLED")
ACTIVATION_REQUIRED=false unless Object.const_defined?("ACTIVATION_REQUIRED")

ExceptionNotification::Notifier.exception_recipients = %w(you@somewhere.com, me@somewhere.com)
ExceptionNotification::Notifier.sender_address = %("Application Error" somethhing@something.com)
ExceptionNotification::Notifier.email_prefix = "[Your Error Report]" 


