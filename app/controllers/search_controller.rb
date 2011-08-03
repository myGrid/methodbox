class SearchController < ApplicationController

  before_filter :login_required, :except => [ :index]
  after_filter :update_last_user_activity

  def index

    @search_query = params[:search_query]
    @search_query||=""

    #SOLR doesn't appear to support lower case "or"
    query = @search_query.upcase

    if (query.nil? or query.strip.empty?)
      flash.now[:notice]="Sorry your query appeared blank. Please try again"
      return
    end

    if (query.include?(' OR ') && query.include?(' AND '))
      flash.now[:notice]='Sorry you can not mix "or" with "and" in the same query. Please try again'
      return
    end

    @results=[]
    #can only search for people if logged in
    if params[:search_type].include?('people') && logged_in?
      find_people(query)
end  
 if params[:search_type].include?('surveys')
      find_surveys(query)
end 
   if params[:search_type].include?('methods')
      find_methods(query)
end  
 if params[:search_type].include?('extracts')
       find_csvarchive(query)
end   
 if params[:search_type].include?('publications')
        find_publications(query)
end
        @results = select_authorised @results

#variable authorisation is done based on the survey so do them last
    if params[:search_type].include?('variables')
        @results += select_authorised_variables find_variables(query)
    end 

    if @results.empty?
      flash.now[:notice]="No matches found for '<b>#{@search_query}</b>'."
    end

  end

  private

  #Note !SOLR_ENABLED is for testing purposes only and will not give as many results as SOLR_ENABLED
  def find_surveys(query)
    if (SOLR_ENABLED)
      @results += Survey.find_by_solr(query, :limit => 1000).results
    else
      @results += Survey.find(:all, :conditions => ["description like ?", '%'+@search_query.downcase+'%'])
    end
    find_previous_searches
  end

  def find_people(query)
    if (SOLR_ENABLED)
      @results += Person.find_by_solr(query, :limit => 1000).results
    else
      @results = @results + Person.find(:all, :conditions => ["last_name like ?", '%'+@search_query.downcase+'%'])
    end
  end

  def find_methods(query)
    if (SOLR_ENABLED)
      @results += Script.find_by_solr(query, :limit => 1000).results
    #else
      #todo
    end
  end

  def find_csvarchive(query)
    if (SOLR_ENABLED)
      @results += Csvarchive.find_by_solr(query, :limit => 1000).results
    #else
      #todo
    end
  end
  
  def find_publications(query)
    if (SOLR_ENABLED)
      @results += Publication.find_by_solr(query, :limit => 1000).results
    #else
      #todo
    end
  end
  
  def find_variables(query)
    if (SOLR_ENABLED)
      Variable.find_by_solr(query, :limit => 1000).results
    end
  end


  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
  end
  
  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised_variables collection
    collection.select {|el| Authorization.is_authorized?("show", nil, el.dataset.survey, current_user)}
  end

  def find_previous_searches
    search=[]
    if logged_in?
      search = UserSearch.all(:order => "created_at DESC", :limit => 5, :conditions => { :user_id => current_user.id})
    end
    @recent_searches = search
  end

end
