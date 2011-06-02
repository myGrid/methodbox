# Use delayed job. Process a new dataset, split it into columns for each variable
# calculate the stats for each variable

module ProcessDatasetJob
  
 class StartJobTask < Struct.new(:dataset_id, :user_id, :separator, :base_host)
    
   require 'fastercsv'
    
   cattr_accessor :logger
   self.logger = RAILS_DEFAULT_LOGGER
    
   def perform
     begin
       dataset = Dataset.find(dataset_id)
       process_dataset(dataset)
       #Get the updated variables
       variables = Variable.all(:conditions => "dataset_id =  #{dataset_id}")
       variables.each do |variable|
         begin
           process_variable(variable)
         rescue Exception => e
           logger.info(Time.now.to_s + " Problem with variable "  + variable.name  + "in " + dataset_id.to_s + " " + e  + " probably just doesn't exist in new dataset")
         end
       end
       dataset.update_attributes(:has_data=>true)
       email_user
     rescue Exception => e 
       logger.error Time.now.to_s + " Problem processing dataset " + dataset.id.to_s + ", "  + e.inspect + e.backtrace
       # send an error message
       Mailer.deliver_dataset_processing_error(dataset_id, user_id, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
     end
   end

    # TODO - surveys need to belong to a user.  datasets need to belong to a user.
    # can different people add datasets to a survey - permissions issue?
    # tell the user that the dataset has been processed. 
    def email_user
      Mailer.deliver_dataset_processed(dataset_id, user_id, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
    end
    
  #split the dataset into columns
  def process_dataset(dataset)
    dataset_file = dataset.uuid_filename
    csv_path = File.join(CSV_FILE_PATH, dataset_file)
    csv_file = File.open(csv_path, "r")
  
    #try and guess the encoding of the file so that the headers mean something
    begin
      cd = CharDet.detect(csv_file.readline)
      encoding = cd['encoding']
    rescue
      encoding="UTF-8"
    ensure
      csv_file.close
    end
    csv_file = File.open(csv_path, "r:" + encoding)
    faster_csv_file = FCSV.new(csv_file, :headers=>true, :return_headers=>true)
    header_line = faster_csv_file.shift
    all_headers = header_line.headers
    #header_line = csv_file.readline
    #header_line.chop!
    #all_headers = header_line.split(separator)
  
    did = dataset.id
    count = all_headers.size
    if count <= 250
      process_part_dataset(dataset, 0, count-1)
    else
      first_column = 0
      last_column = 249
      while first_column < count  
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
    data_directory = File.join(CSV_FILE_PATH, dataset_file.split('.')[0])
    FileUtils.mkdir_p  data_directory
    csv_path = File.join(CSV_FILE_PATH, dataset_file)
    if (!File.exist?csv_path)
      raise "ERROR path not found " + csv_path
    end 
    csv_file = File.open(csv_path, "r")
    if separator == ","
      sep = ','
    else
      sep ='/t'
    end
    faster_csv_file = FCSV.new(csv_file, :headers=>true, :return_headers=>true, :col_sep => sep)
    all_headers = faster_csv_file.shift
    #header_line = csv_file.readline
    #header_line.chop!
    #all_headers = header_line.split(separator)
    if all_headers.size <= last_column
      logger.error Time.now.to_s + " Error processing dataset " + dataset.id.to_s + " Less than expected headers found. Expected " + last_column.to_s + " found " + all_headers.size.to_s
      raise "Incorrect header"
    end
    all_headers.headers.each do |header|
      if (header.match('([A-Za-z0-9]+)') == nil)
        raise "There is an empty column header"
      end
    end
    column_files = []
    all_columns = (first_column..last_column)
    all_columns.each do |column| 
      #make sure there are some characters in the column
      # if !(column['/\S/'].empty?)
      name = all_headers[column].downcase
      variable = Variable.find_by_name_and_dataset_id(name, dataset.id)
      if !variable
        #could be some extraneous characters in the name, so lets try some scrubbing
        name.tr!('"\'',' ')
        name.strip!
        variable = Variable.find_by_name_and_dataset_id(name, dataset.id)
      end      	
      if !variable
        raise "Variable not found " + name + " in dataset " + dataset.id.to_s + " file " + dataset_file
      end
    
      path = File.join(data_directory, name + ".txt")
    #no need for the data_file path since it will be the name of the variable under File.join(CSV_FILE_PATH, dataset_file.split('.')[0])
      file = FCSV.open(path, "w")
      column_files[column] = file 
    end   

    #we have already removed the headers so this is the rest of the rows containing only data
    faster_csv_file.each do |row|   
      all_columns.each do |column|
	row.field(all_headers[column]) != nil ? column_files[column] << row.field(all_headers[column]) : column_files[column] << ''
      end  
    end
  
    csv_file.close
    all_columns.each do |column| 
      column_files[column].close
    end  
  end  

def process_variable(variable)
  #Open data file
  data_path = File.join(CSV_FILE_PATH, variable.dataset.uuid_filename.split('.')[0], variable.name.downcase + ".txt")
  if !data_path
    logger.error Time.now.to_s + " Error processing variable " + variable.id.to_s + " no data_file set"
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
            logger.info Time.now.to_s + " In variable " + variable.name.to_s + " Non number value found " + key.to_s
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
      none_values_distribution_file.write(key.chomp.to_s + "," + frequency.to_s + "\n")
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
    
    #second pass for variance, mode and median
    difference_sum = 0
    counter = 0;
    half_median = nil
    mode = nil
    mode_count = 0
    values.each do |key, frequency|
      #uts key
      difference_sum += ((key - mean) * (key - mean) * frequency)
      counter += frequency
      if counter == count / 2
        #median is mean of value before the middle and value after the middle
        half_median = key
      elsif counter >= count / 2
        if half_median
          variable.median = (key + half_median) /2.0
        else
          variable.median = key
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
  variable.median = nil
  variable.mode = nil
  variable.standard_deviation = nil  
end

end
end
