class HomeController < ApplicationController
  
  before_filter :login_required, :except=> [ :about ]

  before_filter :find_previous_searches, :only => [ :index ]

  layout :select_layout
  
  def about
    respond_to do |format|
        if logged_in?
          format.html {redirect_to index_url}
        else
        format.html # about.html.erb  
      end    
    end
  end
  
  def index
    scripts = Script.all(:order => "created_at DESC", :conditions => { :created_at => (Time.now.midnight - 7.day)..Time.now})
    if scripts.empty?
      scripts = Script.all(:order => "created_at DESC",:limit => 10)
    end
    if scripts.size < 10
      num = 10 - scripts.size
      extra_scripts = Script.all(:order => "created_at DESC",:order => "created_at DESC",:limit => num, :offset => scripts.size)
      scripts.concat(extra_scripts)
    end
    scripts = select_authorised scripts
    archives = Csvarchive.all(:order => "created_at DESC",:conditions => { :created_at => (Time.now.midnight - 7.day)..Time.now})
    if archives.empty?
      archives = Csvarchive.all(:order => "created_at DESC",:limit => 10)
    end
    if archives.size < 10
      num = 10 - archives.size
      extra_archives = Csvarchive.all(:order => "created_at DESC",:order => "created_at DESC",:limit => num, :offset => archives.size)
      archives.concat(extra_archives)
    end
    archives = select_authorised archives
    datasets = Survey.all(:order => "created_at DESC",:conditions => { :created_at => (Time.now.midnight - 7.day)..Time.now})
    if datasets.empty?
      datasets = Survey.all(:order => "created_at DESC",:limit => 10)
    end
    if datasets.size < 10
      num = 10 - datasets.size
      extra_datasets = Survey.all(:order => "created_at DESC",:limit => num, :offset => datasets.size)
      datasets.concat(extra_datasets)
    end
    @results = Array.new
    @results.concat(scripts)
    @results.concat(archives)
    @results.concat(datasets)
    select_authorised collection @results
    respond_to do |format|
      format.html # index.html.erb      
    end
  end
  
  def select_layout
    if logged_in?
      return 'main'
    else
      return 'main_without_sidebar'
    end
  end

  private

  def find_previous_searches
    search=[]
    if logged_in?
      search = UserSearch.all(:order => "created_at DESC", :limit => 5, :conditions => { :user_id => current_user.id})
    end
    @recent_searches = search
  end

  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
  end
end
