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
      results = find_surveys(query, params[:survey_page]).results
      @results_hash['survey'] = results
      surveys = results.sort!{|x,y| x.title <=> y.title}
      surveys_hash = {"total_entries" => surveys.size, "results"=>surveys.collect{ |s| {"id" => s.id, "title" => s.title, "description" => truncate_words(s.description, 50),  "type" => SurveyType.find(s.survey_type).name, "year" => s.year ? s.year : 'N/A', "source" => s.nesstar_id ? s.nesstar_uri : "methodbox"}}}
      puts surveys_hash.to_json
      @surveys_json = surveys_hash.to_json
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
      @results_hash['variable'] = find_variables(query, params[:variable_page]).results.sort!{|x,y| x.name <=> y.name}
    end 

    if @results_hash.empty?
      flash.now[:notice]="No matches found for '<b>#{@search_query}</b>'."
    end
    @results_empty = true
    @results_hash.each_key do |key|
      if !@results_hash[key].empty?
        @results_empty = false
      end
    end
    if @results_empty
      flash[:notice] = "There were no search results for \"" + params[:search_query] + "\""
    end
  end

  private

  def find_surveys(query, page)
    #only search authorised surveys
    #surveys are restricted to certain types at the moment
    surveys = get_surveys
    surveys.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
    surveys.collect!{|el| el.id}
    res = Sunspot.search(Survey) do
      keywords(query) {minimum_match 1}
      with(:id, surveys)
      paginate(:page => page ? page : 1, :per_page => 1000)
    end
    find_previous_searches
    return res
  end

  def find_people(query, page)
    res = Sunspot.search(Person) do
      keywords(query) {minimum_match 1}
      paginate(:page => page ? page : 1, :per_page => 1000)
    end
    return res
  end

  def find_methods(query, page)
    res = Sunspot.search(Script) do
      keywords(query) {minimum_match 1}
      paginate(:page => page ? page : 1, :per_page => 1000)
    end
    return res
  end

  def find_csvarchive(query, page)
    res = Sunspot.search(Csvarchive) do
      keywords(query) {minimum_match 1}
      paginate(:page => page ? page : 1, :per_page => 1000)
    end
    return res
  end
  
  def find_publications(query, page)
    res = Sunspot.search(Publication) do
      keywords(query) {minimum_match 1}
      paginate(:page => page ? page : 1, :per_page => 1000)
    end
    return res
  end
  
  def find_variables(query, page)
    #which datasets can the current user see
    surveys = get_surveys
    surveys.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
    datasets = []
    surveys.each do |survey_id|
      Survey.find(survey_id).datasets.each do |dataset|
       datasets << dataset.id
      end
    end
    result = Sunspot.search(Variable) do
      keywords(query) {minimum_match 1}
      paginate(:page => page ? page : 1, :per_page => 1000)
      with(:dataset_id, datasets)
    end
    variables_hash = {"total_entries"=>result.results.total_entries, "results" => result.results.sort{|x,y| x.name <=> y.name}.collect{|variable| {"id" => variable.id, "name"=> variable.name, "description"=>variable.value, "survey"=>variable.dataset.survey.title, "year" => variable.dataset.survey.year, "category"=>variable.category, "popularity" => VariableList.all(:conditions=>"variable_id=" + variable.id.to_s).size}}}
    @variables_json = variables_hash.to_json
    return result
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

  def get_surveys
    survey_types = SurveyType.all(:conditions=>{:name=>["Research Datasets", "Teaching Datasets","Health Survey for England","General Household Survey"]})
    non_empty_survey_types = []
    survey_types.each do |survey_type|
      any_datasets = false
      survey_type.surveys.each do |survey|
        any_datasets = true unless survey.datasets.empty?
      end
      if any_datasets 
        non_empty_survey_types << survey_type
      end
    end
    surveys = []
    non_empty_survey_types.each do |survey_type|
      survey_type.surveys.each do |survey|
        unless survey.datasets.empty? 
          surveys << survey unless !Authorization.is_authorized?("show", nil, survey, current_user)
        end
      end
    end
    return surveys
  end

end
