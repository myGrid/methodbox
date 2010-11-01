#Update the data extracts and include any metadata files.

require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'xml'

namespace :obesity do
  desc "update data extracts with metadata files"
  task :update_data_extracts_and_metadata  => :environment do
    Csvarchive.all.each do |extract|
      csv_zip_path = File.join(CSV_OUTPUT_DIRECTORY, extract.filename + "_csv.zip")
      # if the data extract zip exists then add metadata to it
      if File.exists?(csv_zip_path)
        puts "Adding metadata to " + extract.title + " : " + extract.filename
         # add the metadata file to the extracts
          #stata files
          stata_zip_path = File.join(CSV_OUTPUT_DIRECTORY, extract.filename + "_stata.zip")

          Zip::ZipFile.open(stata_zip_path) {|zipfile|
            zipfile.get_output_stream("metadata.txt") { |f| f.puts extract.content_blob.data}
          }
          Zip::ZipFile.open(stata_zip_path) {|zipfile|
              data_extract.stata_do_files.each {|do_file|
                zipfile.get_output_stream(do_file.name) { |f| f.puts do_file.data}
              }
          } 
          #spss files
          spss_zip_path = File.join(CSV_OUTPUT_DIRECTORY, extract.filename + "_spss.zip")

          Zip::ZipFile.open(spss_zip_path) {|zipfile|
              zipfile.get_output_stream("metadata.txt") { |f| f.puts extract.content_blob.data}
          }
        else
          puts "no file exists for " + extract.title + " : " + extract.filename
      end
    end
end
end