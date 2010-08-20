#Create the stata do files and the metadata file for all existing csv archives/data extracts
#in the database

require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'xml'

namespace :obesity do
  desc "load metadata from xml"
  task :create_stata_datafiles  => :environment do
    Csvarchive.all.each do |archive|
      #metadata file
      puts archive.title
      variable_hash = Hash.new
      archive.variables.each do |var|
        variable = Variable.find(var)
        puts variable.name
        if (!variable_hash.has_key?(variable.dataset_id))
          variable_hash[variable.dataset_id] = Array.new
        end
        variable_hash[variable.dataset_id].push(var)
      end
      metadata = String.new
      variable_hash.each_key do |key|
        metadata << "\r\n" + Dataset.find(key).survey.title + "\r\n---------------"
        metadata << "\r\n" + Dataset.find(key).name + "\r\n---------------"
        variable_hash[key].each do |var|
          metadata << "\r\nName: " + var.name
          if var.value != nil
            metadata << "\r\nLabel: " + var.value
          end
          if var.category!= nil
            metadata << "\r\nCategory: " + var.category
          end
          if var.dertype!= nil
            metadata << "\r\nDerivation Type: " + var.dertype
          end
          if  var.dermethod!= nil
            metadata << "\r\nDerivation Method: " + var.dermethod.gsub("\n", "\r\n")
          end
          if var.info!=nil
            metadata << "\r\nValue Information: " + var.info.gsub("\n", "\r\n")
          end
          metadata << "\r\n---------------"
        end
        metadata << "\r\n\r\n\r\n---------------\r\n---------------"
      end
      puts metadata
      content_blob = ContentBlob.new(:data => metadata)
      archive.update_attributes(:content_blob=>content_blob)
      
      #do *files*
      do_file_hash = Hash.new
      variable_hash.each_key do |key|
        d = Dataset.find(key)
        do_file = String.new
        do_file << "***Extract title:  " + archive.title + "\r\n"
        do_file << "*** " + d.name + " (dataset)\r\n"
        do_file << "*** " + d.survey.title + " (survey)\r\n"
        do_file << "version " + STATA_VERSION +  "\r\nset more off\r\n"
        do_file << "insheet using \""  + d.name.split(".")[0] + "_selection.csv\", clear\r\n\r\n"
        do_file << "***Variables\r\n\r\n"
        variable_hash[key].each do |var|
          do_file << "*" + var.name + "\r\n"
          if var.value != nil
            do_file << "label var " + var.name + " " + "\"" + var.value + "\"\r\n"
          end
          if !var.value_domains.empty?
            val_doms = String.new
            var.value_domains.each do |value_domain|
             val_doms << value_domain.value + " \"" + value_domain.label + "\" "
            end
            do_file << "label define " + var.name + "_value_domain " + val_doms +"\r\n"
            do_file << "label value " + var.name + " " + var.name + "_value_domain\r\n\r\n"
          else 
            do_file << "\r\n"
          end
        end
      #finally stick the do file in the hash
        puts do_file
        do_file_hash[key] = do_file
      end
      do_file_hash.each_key do |key|
      #write the do file out to the db
        stata_do_file = StataDoFile.new
        stata_do_file.name = Dataset.find(key).name + "_do_file.txt"
        stata_do_file.csvarchive = archive
        stata_do_file.data = do_file_hash[key]
        stata_do_file.save
      end
    end
  end
end