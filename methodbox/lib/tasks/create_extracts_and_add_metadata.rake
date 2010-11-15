#Update the data extracts and include any metadata files.

require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'xml'
require 'zip/zip'
require 'zip/zipfilesystem'

namespace :obesity do
  desc "update data extracts with metadata files"
  task :update_data_extracts_and_metadata  => :environment do
    Csvarchive.all.each do |extract|
      add_data = true
      #firstly move the extracts to the correct place ie data_extract.filename/files
      if File.exists?(File.join(CSV_OUTPUT_DIRECTORY, extract.filename + ".zip"))
        File.move(File.join(CSV_OUTPUT_DIRECTORY, extract.filename + ".zip"), File.join(CSV_OUTPUT_DIRECTORY, extract.filename + "_csv.zip"))
      end
      #is the extract an old one?
      if !File.exists?(File.join(CSV_OUTPUT_DIRECTORY, extract.filename))
        File.makedirs(File.join(CSV_OUTPUT_DIRECTORY, extract.filename))
        #are any of the files missing, if so create the extract from scratch
        if !File.exists(File.join(CSV_OUTPUT_DIRECTORY, extract.filename + "_csv.zip")) || !File.exists(File.join(CSV_OUTPUT_DIRECTORY, extract.filename + "_stata.zip")) || !File.exists(File.join(CSV_OUTPUT_DIRECTORY, extract.filename + "_spss.zip"))
          add_data = false
          variable_hash = Hash.new
          extract.variables.each do |variable|
            if (!variable_hash.has_key?(variable.dataset_id))
              variable_hash[variable.dataset_id] = Array.new
            end
            variable_hash[variable.dataset_id].push(variable.id)
          end
          begin 
            Delayed::Job.enqueue DataExtractJob::StartJobTask.new(variable_hash, User.find(extract.user_id), extract.id, extract.filename, false)
          rescue Exception => e
            logger.error(e)
          end
        else
          
        old_csv_place = File.join(CSV_OUTPUT_DIRECTORY, extract.filename + "_csv.zip")
        new_csv_place = File.join(CSV_OUTPUT_DIRECTORY, extract.filename, extract.filename + "_csv.zip")
        File.move(old_csv_place, new_csv_place)
        old_stata_place = File.join(CSV_OUTPUT_DIRECTORY, extract.filename + "_stata.zip")
        new_stata_place = File.join(CSV_OUTPUT_DIRECTORY, extract.filename, extract.filename + "_stata.zip")
        File.move(old_stata_place, new_stata_place)
        old_spss_place = File.join(CSV_OUTPUT_DIRECTORY, extract.filename + "_spss.zip")
        new_spss_place = File.join(CSV_OUTPUT_DIRECTORY, extract.filename, extract.filename + "_spss.zip")
        File.move(old_spss_place, new_spss_place)
        end
      end
      csv_zip_path = File.join(CSV_OUTPUT_DIRECTORY, extract.filename, extract.title + "_csv.zip")
      puts csv_zip_path
      # if the data extract zip exists then add metadata to it
      if File.exists?(csv_zip_path) && add_data
        puts "Adding metadata to " + extract.title + " : " + extract.filename
         # add the metadata file to the extracts
          #stata files
          stata_zip_path = File.join(CSV_OUTPUT_DIRECTORY, extract.filename, extract.title + "_stata.zip")

          Zip::ZipFile.open(stata_zip_path) {|zipfile|
            zipfile.get_output_stream("metadata.txt") { |f| f.puts extract.content_blob.data}
          }
          #spss files
          spss_zip_path = File.join(CSV_OUTPUT_DIRECTORY, extract.filename, extract.title + "_spss.zip")

          Zip::ZipFile.open(spss_zip_path) {|zipfile|
              zipfile.get_output_stream("metadata.txt") { |f| f.puts extract.content_blob.data}
          }
        else
          puts "no file exists for " + extract.title + " : " + extract.filename
      end
    end
end
end