class SearchController < ApplicationController
  
  before_filter :login_required
  
  def index
    
    @search_query = params[:search_query]
    @search_query||=""
    @search_type = params[:search_type]
    type=@search_type.downcase unless @search_type.nil?

    downcase_query = @search_query.downcase
    
    @results=[]
    case(type)
    when("people")
      @results = Person.multi_solr_search(downcase_query, :limit=>100, :models=>[Person]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    when("surveys")
      @results = Survey.multi_solr_search(downcase_query, :limit=>100, :models=>[Survey]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    when("methods")
      @results = Script.multi_solr_search(downcase_query, :limit=>100, :models=>[Script]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
      #    when ("sops")
      #      @results = Sop.multi_solr_search(downcase_query, :limit=>100, :models=>[Sop]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
      #    when ("studies")
      #      @results = Study.multi_solr_search(downcase_query, :limit=>100, :models=>[Study]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
      #    when ("models")
      #      @results = Model.multi_solr_search(downcase_query, :limit=>100, :models=>[Model]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
      #    when ("data files")
      #      @results = DataFile.multi_solr_search(downcase_query, :limit=>100, :models=>[DataFile]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
      #   when ("investigations")
      #      @results = Investigation.multi_solr_search(downcase_query, :limit=>100, :models=>[Investigation]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
      #   when ("assays")
      #      @results = Assay.multi_solr_search(downcase_query, :limit=>100, :models=>[Assay]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    else
      #slight fudge to allow all HSE datasets to come up since any users are already registered
      @results = Person.multi_solr_search(downcase_query, :limit=>100, :models=>[Person]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
      @results = select_authorised @results
      @results = @results + Script.multi_solr_search(downcase_query, :limit=>100, :models=>[Script]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
      @results = select_authorised @results
      @results = @results + Survey.multi_solr_search(downcase_query, :limit=>100, :models=>[Survey]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)

      #      @results = Person.multi_solr_search(downcase_query, :limit=>100, :models=>[Person, Survey, Script]).results if (SOLR_ENABLED and !downcase_query.nil? and !downcase_query.strip.empty?)
    end

    #    if (type != "surveys")
    #      @results = select_authorised @results
    #    end
    if @results.empty?
      flash[:notice]="No matches found for '<b>#{@search_query}</b>'."
      #    else
      #      flash[:notice]="#{@results.size} #{@results.size==1 ? 'item' : 'items'} matched '<b>#{@search_query}</b>' within their title or content."
    end
    
  end


  private
  

  #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
  def select_authorised collection
    collection.select {|el| Authorization.is_authorized?("show", nil, el, current_user)}
  end
  
end
