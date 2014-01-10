# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'
#require 'metric_fu'
require 'sunspot/rails/tasks'

#MetricFu::Configuration.run do |config|
#  #define which metrics you want to use
#  config.metrics  = [:churn, :saikuro, :stats, :reek, :roodi, :rails_best_practices, :flay]
#  #a few problems getting any graphs except flay on its own to work
#  # config.graphs   = [:flay, :reek, :roodi, :rails_best_practices]
#end


