# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
#config.action_view.cache_template_loading            = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false
#
#
SOLR_ENABLED=true
ACTIVATION_REQUIRED=true

#change to the address that the app is hosted at, can be localhost
config.action_mailer.default_url_options = { :host => "www.something.org" }

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "smtp.something.com",
  :port => 587,
  :domain => "somewhere.org",
  :authentication => :plain,
  :user_name => "you",
  :password => "password"
}
#whether to use ssl or not. The routes.rb uses this
ROUTES_PROTOCOL = "http"
STATISTICS_ROUTE = '/12345/'