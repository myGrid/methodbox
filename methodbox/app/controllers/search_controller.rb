class SearchController < ApplicationController

  before_filter :login_required, :except => [ :index]
  before_filter :local_login_required, :only => [ :index]

  def index

    @search_query = params[:search_query]
    @search_query||=""

    @search_type = params[:search_type]
    type=@search_type.downcase unless @search_type.nil?

    downcase_query = @search_query.downcase

    if (downcase_query.nil? or downcase_query.strip.empty?)
      flash.now[:notice]="Sorry your query appeared blank. Please try again"
      return
    end

    @results=[]
    case(type)
    when("people")
      find_people
      @results = select_authorised @results
    when("surveys")
      find_surveys
      #    all surveys can be searched for the moment
    when("methods")
      find_methods
      @results = select_authorised @results
    when("data extracts")
       find_csvarchive
       @results = select_authorised @results
    when("all")
      #slight fudge to allow all HSE datasets to come up since any users are already registered
      find_people
      find_methods
      find_csvarchive
      @results = select_authorised @results
      find_surveys
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
  def find_surveys
    if (SOLR_ENABLED)
      @results = @results + Survey.multi_solr_search(@search_query.downcase, :limit=>100, :models=>[Survey]).results
    else
      @results = @results + Survey.find(:all, :conditions => ["description like ?", '%'+@search_query.downcase+'%'])
    end
  end

  def find_people
    if (SOLR_ENABLED)
      @results = @results + Person.multi_solr_search(@search_query.downcase, :limit=>100, :models=>[Person]).results
    else
      @results = @results + Person.find(:all, :conditions => ["last_name like ?", '%'+@search_query.downcase+'%'])
    end
  end

  def find_methods
    if (SOLR_ENABLED)
      @results = @results + Script.multi_solr_search(@search_query.downcase, :limit=>100, :models=>[Script]).results
    #else
      #todo
    end
  end

  def find_csvarchive
    if (SOLR_ENABLED)
      @results = @results + Csvarchive.multi_solr_search(@search_query.downcase, :limit=>100, :models=>[Csvarchive]).results
    #else
      #todo
    end
  end


  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    puts current_user
    collection.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
  end

  def local_login_required
    @search_type = params[:search_type]
    type=@search_type.downcase unless @search_type.nil?
    if (type == "surveys")
      return true
    else
      return login_required
    end
  end

end
