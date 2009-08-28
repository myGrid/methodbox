require 'rubygems'
require 'rake'
require 'model_execution'
require 'active_record/fixtures'
require 'fastercsv'

namespace :db do
  desc "load data from csv"
  task :load_data  => :environment do

    table = FCSV.read( name, :headers => true,  :return_headers => true,:col_sep => "\t")

    coltable = table.by_col

    for i in [0..coltable.headers.length-1]
      variable = Variable.new
      header = coltable[i][0]

      for j in [1..coltable.length-1]
        value = coltable[i][j]
      end
    end

    arrayheader = table.headers
    arraycols = table.by_col
    arraycols.headers.length
    survey = Survey.new
    for column in arraycols
      variable = Variable.new

    end

      User.create(:last_name => row[0], :first_name => row[1], :address => row[2], :city => row[3],
      :state => row[4], :zip => row[5], :created_at => Time.now, :updated_at => Time.now)
    end
  
end