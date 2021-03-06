# Use delayed job. Create a data extract for the surveys required and
# email user when finished. Creates files for stata, spss and standard csv
module DataExtractJob
  
  require 'zip/zip'
  require 'zip/zipfilesystem'
  require 'popen4'
  
  class StartJobTask < Struct.new(:variable_hash, :user_id, :data_extract_id, :output_directory, :send_email, :base_host)
    
    cattr_accessor :logger
    self.logger = RAILS_DEFAULT_LOGGER
    
    def perform
      begin
        data_extract = Csvarchive.find(data_extract_id)
        logger.info("performing csv extraction for " + data_extract.title + ", user " + user_id.to_s)
        begin
          create_csv_files
        rescue Exception => e
          #OK then lets try it the old way
          puts "failed with new way " + e
          create_csv_files_from_uuid_files
        end  
        create_metadata_files
        create_stata_do_files
        create_spss_files
        create_zip_file
        data_extract.update_attributes(:complete => true)
      rescue Exception => e
        logger.error(Time.now.to_s + ", Data Extract " + data_extract.id.to_s + "failed, " + e)
        puts e
        data_extract.update_attributes( :failure=>true )
        email_failed_to_user e
        raise e
      end
      #no need to count a cleanup or email failure as a real problem
      begin
       if send_email
          email_complete_to_user
        end
        clean_up_files
      rescue Exception => e
        logger.error(Time.now.to_s + ", Data Extract " + data_extract.id.to_s + "failed, " + e)
      end
    end
    
    def clean_up_files
      variable_hash.each_key {|key|
        dataset = Dataset.find(key)
        csv_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, dataset.name + "_extract.csv")
        spss_csv_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, dataset.name + "_selection_spss_data.txt")
        spss_code_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, dataset.name + "_selection_spss_code.sps")
        FileUtils.remove_file(csv_path)
        FileUtils.remove_file(spss_csv_path)
        FileUtils.remove_file(spss_code_path)
      }
    end
    
    def create_csv_files
      data_extract = Csvarchive.find(data_extract_id)
      user = User.find(user_id)
      logger.info("creating files for " + data_extract.title + ", user " + user.id.to_s)
      puts("creating files for " + data_extract.title + ", user " + user.id.to_s)
      data_extract_directory = File.join(CSV_OUTPUT_DIRECTORY, output_directory)
      FileUtils.mkdir(data_extract_directory)
      variable_hash.each_key do |key|
          dataset = Dataset.find(key)
          if dataset.survey.source != 'nesstar'
            begin
          puts "create csv " + dataset.name + " was ok"
          logger.info("creating csv files for " + dataset.name  + ", " + data_extract.title + ", user " + user.id.to_s)
          puts("creating csv files for " + dataset.name  + ", " + data_extract.title + ", user " + user.id.to_s)
          new_csv_path = File.join(data_extract_directory, dataset.name + "_extract.csv")
          spss_csv_path = File.join(data_extract_directory, dataset.name + "_selection_spss_data.txt")
          new_csv_file = File.new(new_csv_path , "w")
          spss_csv_file = File.new(spss_csv_path , "w")
          dataset_file = dataset.uuid_filename
                   
          #ogger.info("data_directory")
          #ogger.info(data_directory)
          #uts(data_directory)
          
          survey = Survey.find(dataset.survey_id)
          survey_year = survey.year
          names = []
          column_files = []
          variable_hash[key].each do |var|
              #uts(key)
              variable = Variable.find(var)
              name = variable.name.downcase
              names.push(name)
              path = File.join(CSV_FILE_PATH, variable.dataset.uuid_filename.split('.')[0], variable.name.downcase + ".txt")
              file = File.open(path, "r")
              column_files << file
          end
          info = ["row", "year"]
          headers = info + names
          
          # push headers for csv only, not for spss
          header_string = String.new
          headers.each do |header|
            header_string << header + ","
          end
          header_string.chop!
          puts(header_string)
          header_string << "\r\n"
          new_csv_file.write(header_string)
          puts (column_files.to_s) 
          puts (column_files[0]) 
          i = 1
          while (not column_files[0].eof) do
              out_line = i.to_s + "," + dataset.survey.year
              column_files.each do |column_file|
                  line = column_file.readline
                  line.chomp!
                  if line.include? ","
                    line = "\"" + line + "\""
                  end
                  #uts("line:"+line+":")
                  out_line << "," + line
              end            
              # out_line.chop!
              #uts("out_line:"+out_line)
              out_line << "\r\n"
              new_csv_file.write(out_line)
              spss_csv_file.write(out_line)
              i = i + 1
          end 
          #uts("closing")
          new_csv_file.close
          spss_csv_file.close
          #uts (column_files.to_s) 
          column_files.each { |column_file| 
            column_file.close 
          }
          logger.info("completed for " + dataset.name  + ", " + data_extract.title + ", user " + user_id.to_s)
          #uts("Closed")
        # }
      rescue Exception => e
        logger.error(Time.now.to_s + "Problem with data extract " +  data_extract.id.to_s + " and dataset " + dataset.id.to_s)
      end
      end
      end # variable_hash.each_key do |key|
    end #create_csv_files
    
    def email_failed_to_user error
      logger.info("email failure to user")
      Mailer.deliver_data_extract_failed(data_extract_id, user_id, error, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
    end

    def email_complete_to_user
      logger.info("email user")
      Mailer.deliver_data_extract_complete(data_extract_id, user_id, base_host) if EMAIL_ENABLED && User.find(user_id).person.send_notifications?
    end
    
    def create_zip_file
      data_extract = Csvarchive.find(data_extract_id)
      logger.info("create zip files for " + data_extract.title + ", user " + user_id.to_s)
      #csv files
      csv_zip_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, data_extract.filename + "_csv.zip")
      Zip::ZipFile.open(csv_zip_path, Zip::ZipFile::CREATE) {|zipfile|
        variable_hash.each_key {|key|
          dataset = Dataset.find(key)
          if dataset.survey.source != 'nesstar'
          file_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, dataset.name + "_extract.csv")
          zipfile.add(dataset.name + "_extract.csv", file_path)
        end
        }
        zipfile.close
      }
      Zip::ZipFile.open(csv_zip_path) {|zipfile|
        zipfile.get_output_stream("metadata.txt") { |f| f.puts data_extract.content_blob.data}
      }

      #stata files
      stata_zip_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, data_extract.filename + "_stata.zip")
      Zip::ZipFile.open(stata_zip_path, Zip::ZipFile::CREATE) {|zipfile|
        variable_hash.each_key {|key|
          dataset = Dataset.find(key)
          if dataset.survey.source != 'nesstar'

          file_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, dataset.name + "_extract.csv")
          zipfile.add(dataset.name + "_extract.csv", file_path)
        end
        }
          zipfile.close
      }
      Zip::ZipFile.open(stata_zip_path) {|zipfile|
        zipfile.get_output_stream("metadata.txt") { |f| f.puts data_extract.content_blob.data}
      }
      Zip::ZipFile.open(stata_zip_path) {|zipfile|
          data_extract.stata_do_files.each {|do_file|
            zipfile.get_output_stream(do_file.name) { |f| f.puts do_file.data}
          }
      } 
      #spss files
      spss_zip_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, data_extract.filename + "_spss.zip")
      Zip::ZipFile.open(spss_zip_path, Zip::ZipFile::CREATE) {|zipfile|
        variable_hash.each_key {|key|
          dataset = Dataset.find(key)
          if dataset.survey.source != 'nesstar'

          file_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, dataset.name + "_selection_spss_data.txt")
          code_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, dataset.name + "_selection_spss_code.sps")
          zipfile.add(dataset.name + "_selection_spss_data.txt", file_path)
          zipfile.add(dataset.name + "_selection_spss_code.sps", code_path)
        end
        }
        zipfile.close
      }
      Zip::ZipFile.open(spss_zip_path) {|zipfile|
          zipfile.get_output_stream("metadata.txt") { |f| f.puts data_extract.content_blob.data}
      }  
    end
    
    def create_spss_files
      data_extract = Csvarchive.find(data_extract_id)
      logger.info("create stata do files for " + data_extract.title + ", user " + user_id.to_s)
      spss_file_hash = Hash.new
      variable_hash.each_key do |key|
        d = Dataset.find(key)
        spss_file = String.new
        spss_file << "DATA LIST FILE= \"" + d.name + "_selection_spss_data.txt\" free (\",\")\r\n/ "
        var_names = String.new
        variable_hash[key].each do |var|
          variable = Variable.find(var)
          var_names << variable.name.downcase + " "
        end
        var_names.chomp!
        spss_file << var_names
        spss_file << ".\r\n\r\nVARIABLE LABELS\r\n"
        variable_hash[key].each do |var|
          variable = Variable.find(var)
          spss_file << variable.name + " \"" + variable.name + "\"\r\n"
        end
        spss_file << ".\r\n\r\nVALUE LABELS\r\n/\r\n"
        spss_file << "dataset\r\n"
        spss_file << "1 \"" + d.name + "\"\r\n/\r\n"
        spss_file << "survey\r\n"
        spss_file << "1 \"" + d.survey.survey_type.name + "\"\r\n.\r\n\r\nEXECUTE."
        spss_file_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, d.name + "_selection_spss_code.sps")
        file = File.new(spss_file_path, "w")
        file.write(spss_file)
        file.close
      end
    end
    
    def create_spss_files_from_original
      data_extract = Csvarchive.find(data_extract_id)
      logger.info("create stata do files for " + data_extract.title + ", user " + user_id.to_s)
      variable_hash.each_key do |key|
        dataset = Dataset.find(key)
        var_names = String.new
        variable_hash[key].each do |var|
          variable = Variable.find(var)
          var_names << variable.name.downcase + ","
        end
        var_names.chomp!
        spss_input_file_path = File.join(CSV_FILE_PATH, dataset.uuid_filename.split(".")[0] + ".sav")
        spss_output_file_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, dataset.name + "_selection_spss_code.sav")
        command_file_path = File.join(CSV_OUTPUT_DIRECTORY, output_directory, "spss_command.stcmd")
        command_file = File.new(command_file_path, "w")
        command_file << "keep " + var_names + "\n"
        command_file << "copy " + spss_input_file_path  + " " + spss_output_file_path + "\n"
        command_file << "exit"
        command_file.close
        # pipe = IO.popen(STAT_TRANSFER + " " + command_file_path)
        status = Open4::popen4(STAT_TRANSFER) do |pid, stdin, stdout, stderr|
          stdin.puts "ex " + command_file_path
          stdin.puts "exit"
          stdin.close 
        end
      end
    end
    
    #create stata do files for this new extract
    def create_stata_do_files
      data_extract = Csvarchive.find(data_extract_id)
      logger.info("create stata do files for " + data_extract.title + ", user " + user_id.to_s)
      do_file_hash = Hash.new
      variable_hash.each_key do |key|
        d = Dataset.find(key)
        do_file = String.new
        do_file << "***Extract title:  " +  data_extract.title + "\r\n"
        do_file << "*** " + d.name + " (dataset)\r\n"
        do_file << "*** " + d.survey.title + " (survey)\r\n"
        do_file << "version" + STATA_VERSION + "\r\nset more off\r\n"
        do_file << "insheet using \""  + d.name.split(".")[0] + "_selection.csv\", clear\r\n\r\n"
        do_file << "***Variables\r\n\r\n"
        variable_hash[key].each do |var|
          variable = Variable.find(var)
            do_file << "*" + variable.name + "\r\n"
            do_file << "label var " + variable.name + " " + "\"" + variable.value + "\"\r\n"
            if !variable.value_domains.empty?
              val_doms = String.new
              variable.value_domains.each do |value_domain|
                val_doms << value_domain.value + " \"" + value_domain.label + "\" "
              end
              do_file << "label define " + variable.name + "_value_domain " + val_doms +"\r\n"
              do_file << "label value " + variable.name + " " + variable.name + "_value_domain\r\n\r\n"
            else 
              do_file << "\r\n"
            end
        end
        #finally stick the do file in the hash
        do_file_hash[key] = do_file
      end
      do_file_hash.each_key do |key|
        stata_do_file = StataDoFile.new
        stata_do_file.name = Dataset.find(key).name + "_do_file.do"
        stata_do_file.csvarchive = Csvarchive.find(data_extract_id)
        stata_do_file.data = do_file_hash[key]
        stata_do_file.save
      end
    end
    
    def create_metadata_files
      data_extract = Csvarchive.find(data_extract_id)
      logger.info("create metadata files for "  + data_extract.title + ", user " + user_id.to_s)
      metadata = String.new
        variable_hash.each_key do |key|
          metadata << "\r\n" + Dataset.find(key).survey.title + "\r\n---------------"
          metadata << "\r\n" + Dataset.find(key).name + "\r\n---------------"
          variable_hash[key].each do |var|
            variable = Variable.find(var)
            metadata << "\r\nName: " + variable.name
            if variable.value != nil
              metadata << "\r\nLabel: " + variable.value
            end
            if variable.category!= nil
              metadata << "\r\nCategory: " + variable.category
            end
            if variable.dertype!= nil
              metadata << "\r\nDerivation Type: " + variable.dertype
            end
            if  variable.dermethod!= nil
              metadata << "\r\nDerivation Method: " + variable.dermethod.gsub("\n", "\r\n")
            end
            if variable.info!=nil
              metadata << "\r\nValue Information: " + variable.info.gsub("\n", "\r\n")
            end
            metadata << "\r\n---------------"
          end
          metadata << "\r\n\r\n\r\n---------------\r\n---------------"
        end
        content_blob = ContentBlob.new(:data => metadata)
        Csvarchive.find(data_extract_id).update_attributes(:content_blob=>content_blob)
    end
    
    def create_csv_files_from_uuid_files
      data_extract = Csvarchive.find(data_extract_id)
      logger.info("creating files for " + data_extract.title + ", user " + user_id.to_s)
      data_extract_directory = File.join(CSV_OUTPUT_DIRECTORY, output_directory)
      FileUtils.mkdir(data_extract_directory)
      threads = []
      variable_hash.each_key do |key|
        # threads << Thread.new(key.to_s) {
          thread_key = key
          thread_hash = variable_hash
          dataset = Dataset.find(thread_key)
          logger.info("creating thread for " + dataset.name  + ", " + data_extract.title + ", user " + user_id.to_s)
          new_csv_path = File.join(data_extract_directory, dataset.name + "_extract.csv")
          spss_csv_path = File.join(data_extract_directory, dataset.name + "_selection_spss_data.txt")
          new_csv_file = File.new(new_csv_path , "w")
          spss_csv_file = File.new(spss_csv_path , "w")
          dataset_file = dataset.uuid_filename
          survey = Survey.find(dataset.survey_id)
          survey_year = survey.year
          survey_type = survey.survey_type.name
          names = []
          path = File.join(CSV_FILE_PATH, dataset_file)
          csv_file = File.open(path, "r")
          header_line = csv_file.readline
          header_line.chop!
          all_headers = header_line.split("\t")
          header_position = []
          thread_hash[thread_key].each do |var|
            variable = Variable.find(var)
            name = variable.name
            names.push(name.downcase)
            position = all_headers.index(name.downcase)
            if position == nil
              position = all_headers.index(name.upcase)
            end
            header_position.push(position)
          end
          info = ["row", "year"]
          headers = info + names
          
          # push headers for csv and stata only, not for spss
          header_string = String.new
          headers.each do |header|
            header_string << header + ","
          end
          header_string.chop!
          header_string << "\r\n"
          new_csv_file.write(header_string)

          i = 1
          csv_file.each_line do |row|
            line = row.split("\t")
            out_line = i.to_s + "," + dataset.survey.year + ","
            header_position.each do |pos|
              if line[pos].include? ","
                out_line << "\"" + line[pos] + "\","
              else
                out_line << line[pos] + ","
              end
            end
            out_line.chop!
            out_line << "\r\n"
            new_csv_file.write(out_line)
            spss_csv_file.write(out_line)
            i = i + 1
          end
          new_csv_file.close
          spss_csv_file.close
          logger.info("completed for " + dataset.name  + ", " + data_extract.title + ", user " + user_id.to_s)
        # }
      end
      # finished = false
      # finished_count = 0
      # # wait for all the threads to finish
      # until finished == true do
      #   threads.each do |thread| 
      #     if !thread.alive?
      #       finished_count = finished_count + 1
      #     end
      #   end
      #   if finished_count == threads.size
      #     finished = true
      #   else
      #     finished_count = 0
      #   end
      # end
    end
  end
end