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
        variable_hash = Hash.new
        # only count each survey once
        extract.variables.each do |variable|
          if (!variable_hash.has_key?(variable.dataset.survey_id))
            variable_hash[variable.dataset.survey_id] = 1
          end
        end
        # add the counts for this extract to the overall count
        variable_hash.each_key do |key|
          if (!@month.has_key?(key))
            @month[key] = 1
          else
            @month[key] += 1
          end
        end
      end
    
    # last six months
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*180)..Time.now}).each do |download|
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
          if (!@six_months.has_key?(key))
            @six_months[key] = 1
          else
            @six_months[key] += 1
          end
        end
      end
    
    # last year
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*365)..Time.now}).each do |download|
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
          if (!@year.has_key?(key))
            @year[key] = 1
          else
            @year[key] += 1
          end
        end
      end
    
  end
end