#Change the existing link data for scripts and csvarchives to use the link model
#Should only need to run this once if the old db has records which are using the old
#linking model

require 'rubygems'
require 'rake'

namespace :obesity do
  desc "load data from csv"
  task :update_links  => :environment do
    #Find all existing scripts and create new Links for
    #any Data Extracts and Surveys they are already linked to
    #in the current model
    Script.find(:all).each do |script|
      script.csvarchives.each do |extract|
        link = Link.new
        link.subject = script
        link.object = extract
        link.predicate = "link"
        puts "Found link from Script id " + script.id.to_s + " to Data Extract " + extract.id.to_s
        link.save
      end
      script.surveys.each do |survey|
        link = Link.new
        link.subject = script
        link.object = survey
        link.predicate = "link"
        puts "Found link from Script id " + script.id.to_s + " to Survey " + survey.id.to_s
        link.save
      end
    end
    Csvarchive.find(:all).each do |extract|
      extract.scripts.each do |script|
        link = Link.new
        link.subject = extract
        link.object = script
        link.predicate = "link"
        puts "Found link from Data Extract id " + extract.id.to_s + " to Script " + script.id.to_s
        link.save
      end
      extract.surveys.each do |survey|
        link = Link.new
        link.subject = extract
        link.object = survey
        link.predicate = "link"
        puts "Found link from Data Extract id " + extract.id.to_s + " to Survey " + survey.id.to_s
        link.save
      end
    end
  end
end