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
      #firstly move the extracts to the correct place ie data_extract.filename/files
      if File.exists?(File.join(CSV_OUTPUT_DIRECTORY, extract.filename + ".zip"))
        File.move(File.join(CSV_OUTPUT_DIRECTORY, extract.filename + ".zip"), File.join(CSV_OUTPUT_DIRECTORY, extract.filename + "_csv.zip"))
      end
      if !File.exists?(File.join(CSV_OUTPUT_DIRECTORY, extract.filename))
        File.makedirs(CSV_OUTPUT_DIRECTORY, extract.filename)
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
      csv_zip_path = File.join(CSV_OUTPUT_DIRECTORY, extract.filename, extract.title + "_csv.zip")
      puts csv_zip_path
      # if the data extract zip exists then add metadata to it
      if File.exists?(csv_zip_path)
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