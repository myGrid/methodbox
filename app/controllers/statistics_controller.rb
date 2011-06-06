class StatisticsController < ApplicationController

  layout 'main'
  
  # show stats for downloads and 'active' users
  def index
    calculate_downloads_by_time_period
    calculate_active_user_downloads
    any_user_activity
  end
  
  protected
  
  private
  
  # survey downloads by users including unregistered
  def calculate_active_user_downloads
    @download_hash_week = Hash.new
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*7)..Time.now}).each do |download|
      begin
      user = download.user
      if user == nil
        user_id = "unknown_user"
      else
       user_id = user.id
      end
      # a hash of user to whatever they downloaded
        if (!@download_hash_week.has_key?(user_id))
          @download_hash_week[user_id] = Hash.new
        end
        extract = Csvarchive.find(download.resource_id)
        variable_hash = Hash.new
        # only count each survey once
        extract.variables.each do |variable|
          if (!@download_hash_week[user_id].has_key?(variable.dataset.survey_id))
            inner_hash  = @download_hash_week[user_id]
            inner_hash[variable.dataset.survey_id] = 1
          else
             inner_hash  = @download_hash_week[user_id]
             inner_hash[variable.dataset.survey_id] += 1
          end
        end
      rescue
      end
    end
    
    @download_hash_month = Hash.new
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*30)..Time.now}).each do |download|
      begin
      user = download.user
      if user == nil
        user_id = "unknown_user"
      else
       user_id = user.id
      end
      # a hash of user to whatever they downloaded
        if (!@download_hash_month.has_key?(user_id))
          @download_hash_month[user_id] = Hash.new
        end
        extract = Csvarchive.find(download.resource_id)
        variable_hash = Hash.new
        # only count each survey once
        extract.variables.each do |variable|
          if (!@download_hash_month[user_id].has_key?(variable.dataset.survey_id))
            inner_hash  = @download_hash_month[user_id]
            inner_hash[variable.dataset.survey_id] = 1
          else
            inner_hash  = @download_hash_month[user_id]
             inner_hash[variable.dataset.survey_id] += 1
          end
        end
      rescue
      end
    end
    
    @download_hash_six_months = Hash.new
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*180)..Time.now}).each do |download|
      begin
      user = download.user
      if user == nil
        user_id = "unknown_user"
      else
       user_id = user.id
      end
      # a hash of user to whatever they downloaded
        if (!@download_hash_six_months.has_key?(user_id))
          @download_hash_six_months[user_id] = Hash.new
        end
        extract = Csvarchive.find(download.resource_id)
        variable_hash = Hash.new
        # only count each survey once
        extract.variables.each do |variable|
          if (!@download_hash_six_months[user_id].has_key?(variable.dataset.survey_id))
            @download_hash_six_months[user_id][variable.dataset.survey_id] = 1
          else
            @download_hash_six_months[user_id][variable.dataset.survey_id] += 1
          end
        end
      rescue
      end
    end
    @download_hash_year = Hash.new
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*365)..Time.now}).each do |download|
      begin
      user = download.user
      if user == nil
        user_id = "unknown_user"
      else
       user_id = user.id
      end
      # a hash of user to whatever they downloaded
        if (!@download_hash_year.has_key?(user_id))
          @download_hash_year[user_id] = Hash.new
        end
        extract = Csvarchive.find(download.resource_id)
        variable_hash = Hash.new
        # only count each survey once
        extract.variables.each do |variable|
          if (!@download_hash_year[user_id].has_key?(variable.dataset.survey_id))
            @download_hash_year[user_id][variable.dataset.survey_id] = 1
          else
            @download_hash_year[user_id][variable.dataset.survey_id] += 1
          end
        end
      rescue
      end
    end
  end
  
  # downloads in last week, month, six months and year
  def calculate_downloads_by_time_period
    @week = Hash.new
    @month = Hash.new
    @six_months = Hash.new
    @year = Hash.new
    
    # last week
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*7)..Time.now}).each do |download|
      begin
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
    rescue
    end
    end
    
    # last month
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*30)..Time.now}).each do |download|
      begin
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
      rescue 
      end
      end
    
    # last six months
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*180)..Time.now}).each do |download|
      begin
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
      rescue
        
      end
      end
    
    # last year
    Download.all(:conditions => {:resource_type=>"Csvarchive", :created_at => Time.now - (60*60*24*365)..Time.now}).each do |download|
      begin
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
      rescue
      end
      
      end
  end
  
  def any_user_activity
    @active_users = User.all(:conditions => ['last_user_activity is not null']) 
  end
  
end