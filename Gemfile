source 'http://rubygems.org'
source 'http://localhost:8808'
source :gemcutter
gem "rails", "2.3.14"
#rails version depends on active support of same version
gem "activesupport", "2.3.14"
gem "rmagick", "2.13.1"
gem "RedCloth", "4.2.3"
gem "will_paginate", "2.3.12"
gem "fastercsv", "1.5.3"
gem "libxml-ruby", "2.2.0"
gem "mysql", "2.8.1"
gem "ruby-debug", "0.10.3"
gem "rubyzip", "0.9.1"
gem "sqlite3-ruby", :require => "sqlite3"
gem "uuidtools", "2.1.1"
gem "mime-types", "1.16"
gem "rchardet", "1.3"
gem "tzinfo", "0.3.24"
gem "linkeddata", "0.3.1"
gem "ipaddress", "0.7.0"
gem "POpen4",  "0.1.4", :require => "popen4"
gem "nesstar-api"
gem "metric_fu"
gem 'sunspot_rails', '~> 1.2.1'
gem 'addressable', '2.2.4'
gem 'simple-spreadsheet-extractor', '0.5.0'
#popen 4 and windows need the win32-open3 gem
gem 'win32-open3', :platforms=>[:mingw]
gem 'ddi-parser'
gem "recaptcha", :require => "recaptcha/rails"
#later versions cause issues with time to words since {{variable}} is now %{variable} in later versions
gem "i18n", "0.4.1"

#delayed job, any later version can cause issues with pids and script/delayed_job start ie. no workers get started
gem "daemons", "1.0.10"

# linecache is not a gem we pull in directly but it is used by ruby-debug and
# version 0.45 requires ruby 1.9. 0.43 works with 1.8 so specify it here.
gem 'linecache', '0.43'

#stop the 'You have already activated rake 0.9.0, but your Gemfile requires rake 0.8.7. Consider using bundle exec' issue
gem 'rake', '0.8.7'

# bundler requires these gems in all environments
# gem "nokogiri", "1.4.2"
# gem "geokit"



group :development do
  # bundler requires these gems in development
  # gem "rails-footnotes"
end

group :test do
  # bundler requires these gems while running tests
  # gem "rspec"
  # gem "faker"
end
