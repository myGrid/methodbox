class SearchController < ApplicationController

  before_filter :login_required, :except => [ :index]
  after_filter :update_last_user_activity

  def index
    #if nothing has been selected then search for all types
    if !defined? params[:search_type] || params[:search_type].empty?
      params[:search_type] = ['people', 'surveys', 'methods', 'extracts', 'publications', 'variables'] 
    end
    @search_types = params[:search_type]
    @results_hash = Hash.new
    @search_query = params[:search_query]
    @search_query||=""

    #SOLR doesn't appear to support lower case "or"
    query = @search_query.upcase

    if (query.nil? or query.strip.empty?)
      flash[:error]="Sorry your query appeared blank. Please try again"
      redirect_to :back
    end
    #if (query.include?(' OR ') && query.include?(' AND '))
     # flash.now[:notice]='Sorry you can not mix "or" with "and" in the same query. Please try again'
      #return
    #end

    #can only search for people if logged in
    if params[:search_type].include?('people') && logged_in?
      @results_hash['people'] = find_people(query, params[:person_page]).results
    end  
    if params[:search_type].include?('surveys')
      @results_hash['survey'] = find_surveys(query, params[:survey_page]).results
    end 
    if params[:search_type].include?('methods')
      @results_hash['script'] = select_authorised find_methods(query, params[:method_page]).results
    end  
    if params[:search_type].include?('extracts')
     @results_hash['csvarchive'] = select_authorised find_csvarchive(query, params[:csvarchive_page]).results
    end   
    if params[:search_type].include?('publications')
      @results_hash['publication'] = select_authorised find_publications(query, params[:publication_page]).results
    end
    if params[:search_type].include?('variables')
      @results_hash['variable'] = find_variables(query, params[:variable_page]).results
    end 

    if @results_hash.empty?
      flash.now[:notice]="No matches found for '<b>#{@search_query}</b>'."
    end
    @results_hash.each_key do |key|
     puts "results for " + key + " : "  + @results_hash[key].class.to_s + " : "+ @results_hash[key].to_s
    end
  end

  private

  def find_surveys(query, page)
    #only search authorised surveys
    surveys = Survey.all
    surveys.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
    surveys.collect!{|el| el.id}
    res = Sunspot.search(Survey) do
      keywords(query) {minimum_match 1}
      with(:id, surveys)
      paginate(:page => page ? page : 1, :per_page => 50)
    end
    find_previous_searches
    return res
  end

  def find_people(query, page)
    res = Sunspot.search(Person) do
      keywords(query) {minimum_match 1}
      paginate(:page => page ? page : 1, :per_page => 50)
    end
    return res
  end

  def find_methods(query, page)
    res = Sunspot.search(Script) do
      keywords(query) {minimum_match 1}
      paginate(:page => page ? page : 1, :per_page => 50)
    end
    return res
  end

  def find_csvarchive(query, page)
    res = Sunspot.search(Csvarchive) do
      keywords(query) {minimum_match 1}
      paginate(:page => page ? page : 1, :per_page => 50)
    end
    return res
  end
  
  def find_publications(query, page)
    res = Sunspot.search(Publication) do
      keywords(query) {minimum_match 1}
      paginate(:page => page ? page : 1, :per_page => 50)
    end
    return res
  end
  
  def find_variables(query, page)
    #which datasets can the current user see
    surveys = Survey.all
    surveys.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
    datasets = []
    surveys.each do |survey_id|
      Survey.find(survey_id).datasets.each do |dataset|
       datasets << dataset.id
      end
    end
    res = Sunspot.search(Variable) do
      keywords(query) {minimum_match 1}
      paginate(:page => page ? page : 1, :per_page => 50)
      with(:dataset_id, datasets)
    end
    return res
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
