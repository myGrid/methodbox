class SearchController < ApplicationController

  before_filter :login_required, :except => [ :index]
  after_filter :update_last_user_activity

  def index
    @results_hash = {}
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
    
    #only ask solr to fetch results if query is not blank
    if (query.nil? or query.strip.empty?)
      flash.now[:error]="Sorry your query appeared blank. Please try again"
    else
    if params[:survey_select]
      dataset_results = find_datasets(query, params[:survey_page]).results
      survey_results = find_surveys(query, params[:survey_page]).results
      survey_datasets = []
      survey_results.each do |survey|
        survey.datasets.each do |dataset|
          survey_datasets << dataset
        end
      end
      results = dataset_results + survey_datasets
      results.uniq!
      @results_hash['dataset'] = results
      datasets = results.sort!{|x,y| x.name <=> y.name}
      datasets_hash = {"total_entries" => datasets.size, "results"=>datasets.collect{ |d| {"id" => d.id, "title" => d.name, "description" => truncate_words(d.description, 50),  "survey" => d.survey.title, "survey_id" => d.survey.id.to_s, "type" => SurveyType.find(d.survey.survey_type).name, "year" => d.year ? d.year : 'N/A', "source" => d.survey.nesstar_id ? d.survey.nesstar_uri : "methodbox"}}}
      @datasets_json = datasets_hash.to_json
    end 
    if params[:variable_select]
      #don't sort variable results but return by order of relevance
      @results_hash['variable'] = find_variables(query, params[:variable_page]).results
    end
    if params[:script_select]
      @results_hash['script'] = select_authorised find_methods(query, params[:method_page]).results
    end  
    if params[:extract_select]
     @results_hash['csvarchive'] = select_authorised find_csvarchive(query, params[:csvarchive_page]).results
    end   
    if params[:publication_select]
      @results_hash['publication'] = select_authorised find_publications(query, params[:publication_page]).results
    end
    #can only search for people if logged in
    if params[:people_select] && logged_in?
      @results_hash['people'] = find_people(query, params[:person_page]).results
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
      respond_to do |format|
        format.html {redirect_to(:back || root_path)}
      end
    end
    #expires_in 20.minutes
    end
  end

  private

  def find_datasets(query, page)
    #dataset access is based on the parent survey
    #only search authorised surveys
    surveys = get_surveys
    surveys.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
    datasets = []
    surveys.each do |survey|
      survey.datasets.each {|dataset| datasets << dataset}
    end
    datasets.collect!{|el| el.id}
    if params[:dataset_year]
      
    end
    #TODO dataset location and year
    res = Sunspot.search(Dataset) do
        with(:id, datasets)
        #with(:year).between(3.0..5.0)
        paginate(:page => page ? page : 1, :per_page => 1000)
      keywords(query) do
        minimum_match 1
        fields(:name) if params[:dataset_title]
        fields(:description) if params[:dataset_description]
      end
    end
  end

  def find_surveys(query, page)
    #only search authorised surveys
    surveys = get_surveys
    surveys.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
    surveys.collect!{|el| el.id}
    #TODO survey location
    res = Sunspot.search(Survey) do
      keywords(query) do
        minimum_match 1
        fields(:title) if params[:survey_title]
        fields(:title) if params[:survey_description]
      end
      with(:id, surveys)
      paginate(:page => page ? page : 1, :per_page => 1000)
    end
    find_previous_searches
    return res
  end

  def find_people(query, page)
    res = Sunspot.search(Person) do
      keywords(query) do
        minimum_match 1
        fields(:name) if params[:person_name]
        fields(:description) if params[:person_description]
        fields(:expertise) if params[:person_expertise]
      end
      paginate(:page => page ? page : 1, :per_page => 1000)
    end
    return res
  end

  def find_methods(query, page)
    res = Sunspot.search(Script) do
      keywords(query) do
        minimum_match 1
        fields(:title) if params[:extract_title]
        fields(:description) if params[:extract_description]
      end
      paginate(:page => page ? page : 1, :per_page => 1000)
    end
    return res
  end

  def find_csvarchive(query, page)
    res = Sunspot.search(Csvarchive) do
      keywords(query) do
        minimum_match 1
        fields(:title) if params[:extract_title]
        fields(:description) if params[:extract_description]
      end
      paginate(:page => page ? page : 1, :per_page => 1000)
    end
    return res
  end
  
  def find_publications(query, page)
    res = Sunspot.search(Publication) do
      keywords(query) do
        minimum_match 1
        fields(:title) if params[:publication_title]
        fields(:abstract) if params[:publication_description]
        fields(:journal) if params[:publication_journal]
      end
      paginate(:page => page ? page : 1, :per_page => 1000)
    end
    return res
  end
  
  #now handled by XHR request but we need to know if there will be any results
  #in advance of showing the table and generating the request again. A little bit
  #wasteful of cpu but not too much
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
      keywords(query) do
        minimum_match 1
        fields(:name) if params[:variable_name]
        fields(:value) if params[:variable_description]
        fields(:values) if params[:variable_values]
      end
      paginate(:page => params[:page] ? page : 1, :per_page => 20)
      with(:dataset_id, datasets)
    end
    variables_hash = {"startIndex" => 0, "recordsReturned" => 20, "total_entries"=>result.results.total_entries, "results" => result.results.collect{|variable| {"id" => variable.id, "name"=> variable.name, "description"=>variable.value, "dataset"=>variable.dataset.name, "dataset_id"=>variable.dataset.id.to_s, "survey"=>variable.dataset.survey.title, "survey_id"=>variable.dataset.survey.id.to_s, "year" => variable.dataset.year, "category"=>variable.category, "popularity" => VariableList.all(:conditions=>"variable_id=" + variable.id.to_s).size}}}
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

end

