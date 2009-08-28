require 'fastercsv'

class CSVParser

  def parse_file

    variables = Variable.find_by_solr("weight").docs

    var_hash = Hash.new

    puts variables
    
    variables.each do |var|
      i = 0
      survey_name = Survey.find(var.survey_id).original_filename
      survey_year = Survey.find(var.survey_id).year
      puts(var.name + " " + survey_name + " " + survey_year)
      csvfile = FCSV.open( '/Volumes/Data/obesity_data/' + survey_year + "/" + survey_name, :headers => true,  :return_headers => true,:col_sep => "\t")
      headers = csvfile.gets
      var_name = var.name.upcase
      if (headers.index(var_name) == nil)
        var_name = var.name.downcase
      end
#      index = headers.index(var.name.upcase)
      values_array = Array.new
      csvfile.gets
      #add the header as the first value of the array
      values_array.push(var_name)
      #read each line of values
      while (line = csvfile.gets)
        #current value for this particular variable
        puts i
        values_array.push(line.field(var_name))
        i = i+ 1
      end





      #      csvfile.close

      #
      #      #      values_array.push(var.name)
      #      i=0
      #      FasterCSV.foreach('/Volumes/Data/obesity_data/' + survey_year + "/" + survey_name) do |row|
      #        puts i
      #        values_array.push(FasterCSV::parse_line(row[0],:col_sep => "\t")[index])
      #        i = i+1
      #        #        values_array.push(row[index])
      #      end
      

      #      while (line = csvfile.gets)
      #        puts i
      #        values_array.push(line.field(var.name))
      #        i = i +1
      #      end
      #      csvfile.close
      var_hash[var] = values_array
    end

    return var_hash
  end

end