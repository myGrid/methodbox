# Use delayed job. Process a new dataset, split it into columns for each variable
# calculate the stats for each variable

module ProcessDatasetJob
  
  class StartJobTask < Struct.new(:dataset_id, :user_id, :separator)
    
    def perform
      dataset = Dataset.find(dataset_id)
      puts "Calculating statistics for " + dataset.name
      process_dataset(dataset)

      #Get the updated variables
      variables = Variable.find(:all, :conditions => "dataset_id =  #{dataset_id}")
      variables.each do |variable|
        process_variable (variable)
      end
    end
    # TODO - surveys need to belong to a user.  datasets need to belong to a user.
    # can different people add datasets to a survey - permissions issue?
    # tell the user that the dataset has been processed. 
    def email_user
      Mailer.deliver_dataset_processed(dataset_id) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
    end
    
    #split the dataset into columns
def process_dataset(dataset)
  did = dataset.id
  variables = Variable.find(:all, :conditions => "dataset_id =  #{did}")
  count = variables.size
  puts "count " + count.to_s
  if count <= 250
    process_part_dataset(dataset, 0, count-1)
  else
    first_column = 0
    last_column = 249
    while first_column < count  
      puts "first column " + first_column.to_s
      puts "last column " + last_column.to_s
      #uts count.to_s + " < " + count.to_s
      process_part_dataset(dataset, first_column, last_column)
      first_column = last_column + 1
      last_column = last_column + 250
      if last_column >= count
        last_column = count - 1
      end
    end  
  end
end

def process_part_dataset(dataset, first_column, last_column)
  dataset_file = dataset.uuid_filename
  data_directory = CSV_FILE_PATH + "/" + dataset_file.split('.')[0] + "/"
  FileUtils.mkdir_p  data_directory
  csv_path = File.join(CSV_FILE_PATH, dataset_file)
  puts "Reading " + first_column.to_s + " to " + last_column.to_s + " from " + csv_path
  #uts File.exist?(csv_path)
  if (!File.exist?csv_path)
    raise "ERROR path not found " + csv_path
  end 
  csv_file = File.open(csv_path, "r")
  #tat = csv_file.stat
  #uts csv_file.ctime.to_s
  header_line = csv_file.readline
  header_line.chop!
  all_headers = header_line.split(separator)
  if all_headers.size <= last_column
    puts "Error processing dataset " + dataset.id.to_s
    puts "Less than expected headers found"
    puts "Expected " + last_column.to_s + " found " + all_headers.size.to_s
    puts header_line
    raise "Incorrect header"
  end
  #uts last_column
  #uts all_headers.size
  column_files = []
  all_columns = (first_column..last_column)
  #uts all_columns
  all_columns.each do |column| 
    name = all_headers[column].downcase
    variable = Variable.find_by_name_and_dataset_id(name, dataset.id)
    if !variable
      #OK lets try some scrubing
      name.tr!('"\'',' ')
      name.strip!
      #puts name
      variable = Variable.find_by_name_and_dataset_id(name, dataset.id)
    end      	
    if !variable
      raise "Variable not found " + name + " in dataset " + dataset.id.to_s + " file " + dataset_file
    end
    #uts column_files.size
    
    path = File.join(data_directory.chop, name + ".txt")
    variable.data_file = path
    variable.save
    file = File.open(path, "w")
    #uts file
    column_files[column] = file
    #uts column_files[column]
  end     
  #uts "all files open"
  
  #copy data
  csv_file.each_line do |row|
    line = row.split(separator)
    line.chop!      
    all_columns.each do |column| 
      column_files[column].write(line[column] + "\n")
    end  
  end
  #uts "done copy data"
  
  #close
  csv_file.close
  all_columns.each do |column| 
    column_files[column].close
  end  
  #uts "done close"
end  

def process_variable(variable)
  #Open data file
  data_path = variable.data_file
  if !data_path
    puts "Error processing variable " + variable.id.to_s + " no data_file set"
    return
  end  
  if !File.readable?(data_path)
    raise "unable to read " + data_path + " from variable " + variable.id.to_s
  end  
  data_file = File.open(data_path, "r")
  #uts (data_path + " open")
  
  #Save data in a String hash
  string_hash = Hash.new(0)
  data_file.each_line do |line|
    if line
      frequency = string_hash[line]
      frequency += 1
      string_hash[line]= frequency
    end  
  end
  data_file.close
  variable.number_of_unique_entries = string_hash.size.to_s

  # open files for writing 
  none_values_distribution_path = data_path.sub(".txt",".csv")
  none_values_distribution_file = File.open(none_values_distribution_path, "w")
  variable.none_values_distribution_file = none_values_distribution_path
  values_distribution_path = data_path.sub(".txt",".data")
  values_distribution_file = File.open(values_distribution_path, "w")
  variable.values_distribution_file = values_distribution_path

  #Parse data into numbers
  sum = 0
  count = 0.0
  positive_values = 0
  blanks = 0
  values_hash = Hash.new(0)
  none_values_hash = Hash.new(0)
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
            puts "In variable " + variable.name.to_s
            puts "Non number value found " + key.to_s
          end  
          strings = true;
          value = nil
        end  
      end  
        
      if !value 
        #Assumptions: all non numerical values are none values
        none_values_hash[key] = frequency
      elsif value < 0
        #Assumptions: all negative numbers are none values
        none_values_hash[value] = frequency
      else
        values_hash[value] = frequency
        sum += (value * frequency)
        count += frequency
        positive_values += 1
      end  
    end  
  end
  variable.number_of_blank_rows = blanks
  variable.number_of_unique_values = values_hash.size
  
  #Found a String so treat all values as Strings
  #Required because found a "9999999999999999999999999999999999999999999999999" in a String column
  if strings
    string_hash.sort.each do |key, frequency|
      none_values_distribution_file .write(key.to_s + "," + frequency.to_s + "\n")
    end
    values_distribution_file.close
    no_value_stats(variable)
    variable.save
    return
  end  
    
  #Write the non values if any
  if none_values_hash.size > 0 
    none_values_hash.sort.each do |key, frequency|
      none_values_distribution_file .write(key.to_s + "," + frequency.to_s + "\n")
    end
  end  
  none_values_distribution_file .close

  #Process the values if any
  if values_hash.size > 0       
    values = values_hash.sort

    #Write the values
    values.each do |key, frequency|
      values_distribution_file.write(key.to_s + "," + frequency.to_s + "\n")
    end  
    values_distribution_file.close

    #Calculate statis from first pass
    variable.min_value = values.first[0]
    variable.max_value = values.last[0]
    mean = (sum / count)
    variable.mean = mean 
    
    #second pass for variance, mode and medium
    difference_sum = 0
    counter = 0;
    half_medium = nil
    mode = nil
    mode_count = 0
    values.each do |key, frequency|
      #uts key
      difference_sum += ((key - mean) * (key - mean) * frequency)
      counter += frequency
      if counter == count / 2
        #medium is mean of value before the middle and value after the middle
        half_medium = key
      elsif counter >= count / 2
        if half_medium
          variable.medium = (key + half_medium) /2.0
        else
          variable.medium = key
        end  
        counter = - count
      end
      if mode_count == frequency
        mode = nil
      elsif mode_count < frequency
        #uts "new mode " + key.to_s
        mode = key
        mode_count = frequency
      end  
    end
    variable.mode = mode
    variable.standard_deviation = Math.sqrt(difference_sum / count)
  else 
    #make sure all the stats values are null
    values_distribution_file.close
    no_value_stats(variable)
  end  
    
  #Save the value
  variable.save

  #close all open files
end

def no_value_stats(variable)
  variable.min_value = nil
  variable.max_value = nil
  variable.mean = nil
  variable.medium = nil
  variable.mode = nil
  variable.standard_deviation = nil  
end

end
end