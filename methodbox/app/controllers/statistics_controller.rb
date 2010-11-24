class StatisticsController < ApplicationController

  layout 'main'
  
  # how many downloads per time period
  def index
    @week = Hash.new
    @month = Hash.new
    @six_months = Hash.new
    @year = Hash.new
    
    # last week
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*7)..Time.now}).each do |download|
      extract = Csvarchive.find(download.resource_id)
      variable_hash = Hash.new
      # only count each survey once
      extract.variables.each do |variable|
        if (!variable_hash.has_key?(variable.dataset.survey_id))
          variable_hash[variable.dataset.survey_id] = 1
        end
      end
      # add the counts for this extract to the overall count
      variable_hash.each_key do |key|
        if (!@week.has_key?(key))
          @week[key] = 1
        else
          @week[key] += 1
        end
      end
    end
    
    # last month
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*30)..Time.now}).each do |download|
      extract = Csvarchive.find(download.resource_id)
      extract.variables.each do |variable|
        if (!@month.has_key?(variable.dataset.survey_id))
          @month[variable.dataset.survey_id] = 0
        end
        @month[variable.dataset.survey_id] += @month[variable.dataset.survey_id]
      end
    end
    
    # last six months
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*180)..Time.now}).each do |download|
      extract = Csvarchive.find(download.resource_id)
      extract.variables.each do |variable|
        if (!@six_months.has_key?(variable.dataset.survey_id))
          @six_months[variable.dataset.survey_id] = 0
        end
        @six_months[variable.dataset.survey_id] += @six_months[variable.dataset.survey_id]
      end
    end
    
    # last year
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*365)..Time.now}).each do |download|
      extract = Csvarchive.find(download.resource_id)
      extract.variables.each do |variable|
        if (!@year.has_key?(variable.dataset.survey_id))
          @year[variable.dataset.survey_id] = 0
        end
        @year[variable.dataset.survey_id] += @year[variable.dataset.survey_id]
      end
    end
    
  end
end