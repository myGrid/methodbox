require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'fastercsv'

namespace :obesity do
  desc "add value domains and statistics for mb native variables"
  task :redo_value_domains => :environment do

    dataset = Dataset.all(:conditions=>["nesstar_id is ?", nil]).first
    #Dataset.all(:conditions=>["nesstar_id is ?", nil]).each do |dataset|
      puts("Updating dataset: " + dataset.name + " : " + dataset.id.to_s)
      dataset.variables.each do |variable|
        var_hash = variable.values_hash
        no_var_hash = variable.none_values_hash
        valid_entries = 0
        invalid_entries = 0
        var_hash.each_key do |key|
          valid_entries += var_hash[key]
        end
        no_var_hash.each_key do |key|
          invalid_entries += no_var_hash[key]
        end
        total_entries = 0
        total_entries += valid_entries
        total_entries += invalid_entries
        variable.number_of_blank_rows ? total_entries += variable.number_of_blank_rows : ''
        variable.update_attributes(:valid_entries=> valid_entries, :invalid_entries=>invalid_entries, :total_entries=>total_entries)
        #destroy any existing value domains since the reference has to be the new ones
        #but use all the old value domain labels if there are any
        labels = Hash.new
        variable.value_domains.each do |value_domain|
          begin
            labels[Integer(value_domain.value.to_i)] = value_domain.label
            value_domain.destroy
          rescue Exception => e
            #probably a float so it doesn't really matter
            puts "float for " + variable.id.to_s + ". " + e
          end
        end
        #do the none values first (-1,-2 etc)
        begin
          file = File.open(File.join(CSV_FILE_PATH, variable.dataset.uuid_filename.split('.')[0], variable.name.downcase + ".csv"), "r")
          file.each_line do |line|
            parts = line.split(",")  
            frequency = Integer(parts[parts.size - 1])
            #might be commas in the value so remove the frequency from the line using gsub
            value = line.gsub("," + parts[parts.size - 1], "")
            valDom = ValueDomain.new(:variable => variable, :value => value)
            value_int = Integer(value.to_i)
            labels.has_key?(value_int) ? valDom.label = labels[value_int] : valDom.label = "N/A"
            valDom.save
            puts("Added value for variable " + variable.id.to_s + " : " + value)
            if valDom.value_domain_statistic == nil
              valDomStat = ValueDomainStatistic.new(:value_domain => valDom, :frequency => frequency)
              valDomStat.save
              puts("Added stat for none value variable " + variable.id.to_s + " : " + frequency.to_s)
            end
          end  
          file.close()
          #puts("Added none values for variable " + variable.id.to_s)
        rescue Exception => e
          puts("Problem with none value stats for variable " + variable.id.to_s + ". " + e)
        end
        #then the values
        begin
          file = File.open(File.join(CSV_FILE_PATH, variable.dataset.uuid_filename.split('.')[0], variable.name.downcase + ".data"), "r")
          file.each_line do |line|
            parts = line.split(",")  
            frequency = Integer(parts[parts.size - 1])
            #might be commas in the value so remove the frequency from the line using gsub
            value = line.gsub("," + parts[parts.size - 1], "")
            valDom = ValueDomain.new(:variable => variable, :value => value)
            begin
              value_int = Integer(value)
              labels.has_key?(value_int) ? valDom.label = labels[value_int] : valDom.label = "N/A"
            rescue Exception => e
              #value is probably a float
              puts "float label for " + variable.id.to_s + ". " + e
              valDom.label = "N/A"
            end
            valDom.save
            puts("Added value for variable " + variable.id.to_s + " : " + value + " : " + frequency.to_s)
            if valDom.value_domain_statistic == nil
              valDomStat = ValueDomainStatistic.new(:value_domain => valDom, :frequency => frequency)
              valDomStat.save
              puts("Added stat for value variable " + variable.id.to_s + " : " + frequency.to_s)
            end
          end  
          file.close()
          #puts("Added values for variable " + variable.id.to_s)
        rescue Exception => e
          puts("Problem with stats for variable " + variable.id.to_s + ". " + e)
        end
      #end
    end
  end
end
