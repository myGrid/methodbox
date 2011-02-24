# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "nesstar-api/version"

Gem::Specification.new do |s|
  s.name        = "nesstar-api"
  s.version     = Nesstar::Api::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ian Dunlop"]
  s.email       = ["ian.dunlop@manchester.ac.uk"]
  s.homepage    = "http://github.com/mygrid/methodbox/nesstar-api"
  s.summary     = %q{Simple API for calling NESSTAR API and returning results}
  s.description = %q{This gem provides access to NESSTAR API calls from a data provider}

  s.rubyforge_project = "nesstar-api"
  candidates         = Dir.glob("{bin,lib,test}/**/*")
  s.files            = candidates.delete_if {|item| item.include?("rdoc")}
  # s.test_file        = "test/ts_nesstar-api.rb"
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency("nokogiri", "1.4.4")
  s.add_dependency("rubytree", "0.8.1")
  s.add_dependency("libxml-ruby","1.1.4")
end
