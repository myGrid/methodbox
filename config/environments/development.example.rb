# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

SOLR_ENABLED=false

ACTIVATION_REQUIRED=false

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