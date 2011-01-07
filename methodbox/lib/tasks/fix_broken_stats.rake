#User searches now belong to a user rather than person.
#Run this task to update the db

require 'rubygems'
require 'rake'

namespace :obesity do
  desc "preprocess the data"
  task :check_for_strings_in_statistics => :environment do
    puts "looking for strings"
    #Dataset.find(:all, :conditions => "id = 22").each do |dataset|
    Dataset.find(:all).each do |dataset|
      variables = Variable.find(:all, :conditions => "dataset_id =  #{dataset.id} and data_file = NULL and is_archived != true")
      
        puts "Checking statistics for " + dataset.name
        #Get the updated variables
        variables = Variable.find(:all, :conditions => "dataset_id =  #{dataset.id}")
        #variables = Variable.find(:all, :conditions => "dataset_id =  22 and name = 'INTYP01'")
        variables.each do |variable|
          check_this_variable(variable)
        end
    end 

    puts "Finished checking data"
  end  

  def check_this_variable(variable)
    #Open data file
    data_path = File.join(CSV_FILE_PATH, variable.dataset.uuid_filename.split(".")[0], variable.name.downcase + ".txt")
    data_file = File.open(data_path, "r")
    blanks = 0
    
    string_hash = Hash.new(0)
    data_file.each_line do |line|
      if line
        frequency = string_hash[line]
        frequency += 1
        string_hash[line]= frequency
      end  
    end
    data_file.close

    #Parse data into numbers
    strings = false
    string_hash.each do |key, frequency|
      #uts key
      if !key || key.strip.empty?
        blanks += frequency
      else  
        begin
            value = Integer(key)
        rescue
          begin
            value = Float(key)
          rescue
            if !strings
              #fix the stats file by removing the rogue new lines
              stats_file_path = File.join(CSV_FILE_PATH, variable.dataset.uuid_filename.split(".")[0], variable.name.downcase + ".csv")
              stats_file = File.open(stats_file_path, "r")
              renamed_stats_file_path = File.join(CSV_FILE_PATH, variable.dataset.uuid_filename.split(".")[0], variable.name.downcase + "_old.csv")
              new_stats_file_path = File.join(CSV_FILE_PATH, variable.dataset.uuid_filename.split(".")[0], variable.name.downcase + "_new.csv")
              new_stats_file = File.open(new_stats_file_path, "w")
              even = false
              stat = String.new
              stats_file.each_line do |line|
                if even
                  stat = stat + line
                  puts "new stat " + stat
                  new_stats_file.write(stat)
                  even = false
                  stat = ""
                else
                  stat = line
                  stat.chomp!
                  even = true
                end
              end
              stats_file.close
              new_stats_file.close
              #switch the new and old files around
              FileUtils.mv(stats_file_path, renamed_stats_file_path)
              FileUtils.mv(new_stats_file_path, stats_file_path)
              puts "In dataset " + variable.dataset.name + " filename " + variable.dataset.uuid_filename
              puts "In variable " + variable.name.to_s
              puts "Non number value found " + key.to_s
            end  
            strings = true;
            value = nil
          end  
        end
  end
end
end
end