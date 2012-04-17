source 'http://rubygems.org'
source 'http://localhost:8808'
source :gemcutter
gem "rails", "3.2"
#rails version depends on active support of same version
#gem "activesupport", "2.3.14"
gem "rmagick"
#gem "RedCloth", "4.2.3"
gem "will_paginate", "~> 3.0"
#gem "fastercsv", "1.5.3"
gem "libxml-ruby", ">= 2.2.0"
#gem "ruby-debug", "0.10.3"
gem "rubyzip", "~> 0.9.5"
gem "uuidtools", "~> 2.1.2"
#gem "mime-types", "1.16"
#rchardet is not ruby 1.9 compatible so use a plugin instead
#gem "rchardet", "~> 1.3"
gem "tzinfo", "~> 0.3.31"
gem "linkeddata", "~> 0.3.4"
gem "ipaddress", "~> 0.8.0"
gem "POpen4",  "~> 0.1.2", :require => "popen4"
gem "nesstar-api", ">= 0.0.6"
#rcov not 1.9 compatible
#gem "metric_fu"
gem 'sunspot_rails'
gem 'addressable', '~> 2.2.6'
gem 'simple-spreadsheet-extractor', '0.5.0'
#popen 4 and windows need the win32-open3 gem
gem 'win32-open3', :platforms=>[:mingw]
gem 'ddi-parser', '~> 0.0.4'
gem "recaptcha", :require => "recaptcha/rails"
gem "i18n", "~> 0.6.0"
gem "delayed_job", "~> 3.0.0"
gem 'jquery-rails'
gem "acts-as-taggable-on", "~> 2.2.2"
#fleximage not compatible with rails 3.1
gem "paperclip", "~> 2.0"
gem 'exception_notification'
gem 'devise'
gem 'progress_bar'


#database adaptors
#need the odbc gem for sqlserver
#TODO some rails 3.2 issues with the sql server gems - need to switch to tinytds
#gem "ruby-odbc"
#gem "activerecord-sqlserver-adapter", "~> 3.1.5"
gem "mysql2", "~> 0.3.11"
gem "sqlite3-ruby", :require => "sqlite3"

#delayed job, any later version can cause issues with pids and script/delayed_job start ie. no workers get started
gem "daemons", "1.0.10"

# linecache is not a gem we pull in directly but it is used by ruby-debug and
# version 0.45 requires ruby 1.9. 0.43 works with 1.8 so specify it here.
#gem 'linecache', '0.43'

#stop the 'You have already activated rake 0.9.0, but your Gemfile requires rake 0.8.7. Consider using bundle exec' issue
#gem 'rake', '0.8.7'

# bundler requires these gems in all environments
# gem "nokogiri", "1.4.2"
# gem "geokit"



group :development do
  # bundler requires these gems in development
  # gem "rails-footnotes"
    gem 'sunspot_solr'
end

group :test do
  # bundler requires these gems while running tests
  # gem "rspec"
  # gem "faker"
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
end
