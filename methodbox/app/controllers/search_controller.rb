class SearchController < ApplicationController

  before_filter :login_required, :except => [ :index]
  before_filter :local_login_required, :only => [ :index]

  def index

    @search_query = params[:search_query]
    @search_query||=""

    @search_type = params[:search_type]
    type=@search_type.downcase unless @search_type.nil?

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
    case(type)
    when("people")
      find_people(query)
      @results = select_authorised @results
    when("surveys")
      find_surveys(query)
      @results = select_authorised @results
    when("methods")
      find_methods(query)
      @results = select_authorised @results
    when("data extracts")
       find_csvarchive(query)
       @results = select_authorised @results
    when("publications")
        find_publications(query)
        @results = select_authorised @results
    when("all")
      find_people(query)
      find_methods(query)
      find_csvarchive(query)
      find_publications(query)
      find_surveys(query)
      @results = select_authorised @results
    else
      logger.info("Unexpected search_type "+@search_query)
      flash[:error]="Unexpected search_type"
      redirect_to root_url
    end

    #uts "SEARCH RESULTS: " + @results.to_s
    if @results.empty?
      puts "flashing no matches"
      flash.now[:notice]="No matches found for '<b>#{@search_query}</b>'."
      #    else
      #      flash[:notice]="#{@results.size} #{@results.size==1 ? 'item' : 'items'} matched '<b>#{@search_query}</b>' within their title or content."
    end

  end

  private

  #Note !SOLR_ENABLED is for testing purposes only and will not give as many results as SOLR_ENABLED
  def find_surveys(query)
    if (SOLR_ENABLED)
      @results = @results + Survey.find_by_solr(query, :limit => 1000).results
    else
      @results = @results + Survey.find(:all, :conditions => ["description like ?", '%'+@search_query.downcase+'%'])
    end
  end

  def find_people(query)
    puts "query = " + query
    if (SOLR_ENABLED)
      #results = Variable.find_by_solr(query, :limit => 1000)
      #@results = @results + results.docs
      @results = @results + Person.find_by_solr(query, :limit => 1000).results
    else
      @results = @results + Person.find(:all, :conditions => ["last_name like ?", '%'+@search_query.downcase+'%'])
    end
  end

  def find_methods(query)
    if (SOLR_ENABLED)
      @results = @results + Script.find_by_solr(query, :limit => 1000).results
    #else
      #todo
    end
  end

  def find_csvarchive(query)
    if (SOLR_ENABLED)
      @results = @results + Csvarchive.find_by_solr(query, :limit => 1000).results
    #else
      #todo
    end
  end
  
  def find_publications(query)
    if (SOLR_ENABLED)
      @results = @results + Publication.find_by_solr(query, :limit => 1000).results
    #else
      #todo
    end
  end


  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
  end

  # Surveys and Data Extracts can be searched for by non logged in users
  def local_login_required
    @search_type = params[:search_type]
    type=@search_type.downcase unless @search_type.nil?
    if (type == "surveys" || type == "data extracts")
      return true
    else
      return login_required
    end
  end

end
