#Use to populate variables for a dataset which does not yet have any xml based
#metadata file.  It reads the header line from a tab delimited csv type file and creates
#variables for each of the column headers. Change survey_id to match the appropriate survey
#and f to load the correct tab file

require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'fastercsv'

namespace :obesity do
  desc "load data from csv"
  task :load_single_datafile  => :environment do
    dataset_id = 38
    f = FCSV.open("/Users/Ian/obesity_data/csv/hse08ah.tab", :headers => true,  :return_headers => true,:col_sep => "\t")
    h = f.readline
   
    h.each do |variable_name|

      puts "New Variable " + variable_name[0]
      variable = Variable.new
      variable.name = variable_name[0]
      #        variable.value= variable_value
      #        variable.dertype = variable_dertype
      #        variable.dermethod = variable_dermethod
      #        variable.info = variable_info
      #        variable.category = variable_category
      variable.dataset_id = dataset_id;
      variable.save

    end
    #    table = FCSV.read( name, :headers => true,  :return_headers => true,:col_sep => "\t")
    #
    #    coltable = table.by_col
    #
    #    for i in [0..coltable.headers.length-1]
    #      variable = Variable.new
    #      header = coltable[i][0]
    #
    #      for j in [1..coltable.length-1]
    #        value = coltable[i][j]
    #      end
    #    end
    #
    #    arrayheader = table.headers
    #    arraycols = table.by_col
    #    arraycols.headers.length
    #    survey = Survey.new
    #    for column in arraycols
    #      variable = Variable.new
    #
    #    end
    #
    #      User.create(:last_name => row[0], :first_name => row[1], :address => row[2], :city => row[3],
    #      :state => row[4], :zip => row[5], :created_at => Time.now, :updated_at => Time.now)
  end
  
end
