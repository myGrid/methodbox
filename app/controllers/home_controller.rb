class HomeController < ApplicationController
  
  before_filter :authenticate_user!, :except=> [ :about, :search ]

  before_filter :find_previous_searches, :only => [ :index ]

  layout :select_layout
  
  def search
    #always show the advanced controls (?)
    #if params[:advanced_controls]
      @advanced_controls = true
    #else
      #@advanced_controls = false
    #end
    respond_to do |format|
        format.html # about.html.erb  
    end    
  end

  def about
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
    select_authorised @results
    respond_to do |format|
      format.html # index.html.erb      
    end
  end
  
  def select_layout
    if action_name == 'about'
      return 'main_without_sidebar'
    elsif action_name == 'search'
      return 'main'
    elsif user_signed_in? && action_name != 'search'
      return 'main'
    else
      return 'main_without_sidebar'
    end
  end

  private

  def find_previous_searches
    search=[]
    if user_signed_in?
      search = UserSearch.all(:order => "created_at DESC", :limit => 5, :conditions => { :user_id => current_user.id})
    end
    @recent_searches = search
  end

  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
  end
end
