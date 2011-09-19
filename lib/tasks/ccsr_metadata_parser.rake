#Correct the survey types by reading the esds survey xml page and the ddi metadata

require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'fastercsv'
require 'ddi-parser'

namespace :obesity do
  desc "load metadata from ccsr ddi xml files and redo mb survey types"
  task :parse_ccsr_ddi_metadata  => :environment do
    parser = DDI::Parser.new
    url = URI.parse("http://www.ccsr.ac.uk/esds/variables/xml/")
    res = Net::HTTP.get url
    doc = Nokogiri::HTML(res)
    list = doc.css('li')
    list.each do |li|
      links = li.css("a")
      name = links[0].children.text
      type = name.split(',')[0]
      #name.split(',')[1] != nil ? year = name.split(',')[1] : year = 'N/A'
      match = name.match('(19|20)[0-9][0-9]')
      match != nil ? year = match[0] : year = 'N/A' 
      filename = String.new
      links.each do |link|
        if link.children.text == "DDI"
          filename = link.attributes["href"].value
        end 
      end
      puts name + " : " + type + " : " + filename + " : " + year
      ddi_url = URI.parse("http://www.ccsr.ac.uk/esds/variables/xml/" + filename)
    end
  end
  
end
