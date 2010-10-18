class SurveysController < ApplicationController
  
  before_filter :is_user_admin_auth, :only =>[ :new, :create]

  before_filter :login_required, :except => [ :help, :help2, :index, :search_variables, :sort_variables, :show, :exhibit]

  before_filter :find_previous_searches, :only => [ :index]

  before_filter :find_surveys, :only => [ :index, :search_variables ]

  before_filter :find_previous_searches, :only => [ :index ]

  #before_filter :find_survey_auth, :except => [ :index, :new, :create,:survey_preview_ajax, :help ]

  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]

  before_filter :check_search_parameters, :only => [:search_variables]

  before_filter :rerouted_search, :only => [:show]

  before_filter :find_survey, :only => [:show, :edit, :update]

  #ajax remote for displaying the surveys for a specific survey type
  def show_datasets_for_categories
    survey_type = SurveyType.find(params[:survey_type_id])
    @surveys= Survey.all(:conditions=>({:survey_type_id=>survey_type.id}))
    find_all_categories survey_type.id
    render :update, :status=>:created do |page|
      page.replace_html "categories", :partial=>"surveys/survey_categories"
    end
  end
  
  #display all the different survey types
  def category_browse
    @survey_types = SurveyType.all
  end
  # browse surveys using exhibit
  def exhibit
    puts "exhibit json"
    @surveys_json = "{types:{\"Dataset\":{pluralLabel:\"Datasets\"}},"
     @surveys_json << "\"items\":["
      Survey.all.each do |survey|
        # @surveys_json << "{\"label\":\"" + survey.title + "\",\"year\":\"" + survey.year + "\",\"type\" : \"Survey\",\"survey_description\" :\"" + survey.description
        #        @surveys_json << "\",\"survey_type\":\"" + survey.survey_type.shortname + "\"},"
        survey.datasets.each do |dataset|
          @surveys_json << "{\"label\":\"" + dataset.id.to_s + "\",\"name\":\"" + dataset.name + "\",\"survey-type\":\"" + survey.survey_type.shortname + "\",\"year\":\"" + survey.year + "\",\"type\" : \"Dataset\",\"dataset-description\" :\"" + dataset.description
          @surveys_json << "\",\"Survey\":\"" + survey.title + "\",\"survey-description\" :\"" + survey.description + "\"},"
        end
      end
      @surveys_json.chop!
      @surveys_json << "]}"
      puts @surveys_json.to_s
  end
  
  #only show 'my' links or 'all' links
  def show_links
    source_archives = []
    source_surveys = []
    source_scripts = []
    target_archives = []
    target_surveys = []
    target_scripts = []
    #publications link to something, not from
    @publications = []
    case params[:link_state]
    when "mine"
      source_archives = []
      source_scripts = []
      # no survey link to publications yet, maybe in the future
      # source_publications = []

      links = Link.find(:all, :conditions => { :object_type => "Survey", :object_id => @survey.id, :predicate => "link",:user_id=>current_user.id })

      links.each do |link|
        case link.subject.class.name
        when "Csvarchive"
          source_archives.push(link.subject)
        when "Script"
          source_scripts.push(link.subject)
        # when "Publication"
        #         source_publications.push(link.subject)
        end
      end

      @archives = source_archives
      @scripts = source_scripts
    when "all"
      source_archives = []
      source_scripts = []
      # no survey link to publications yet, maybe in the future
      # source_publications = []

      links = Link.find(:all, :conditions => { :object_type => "Survey", :object_id => params[:survey_id], :predicate => "link" })

      links.each do |link|
        case link.subject.class.name
        when "Csvarchive"
          source_archives.push(link.subject)
        when "Script"
          source_scripts.push(link.subject)
        # when "Publication"
        #         source_publications.push(link.subject)
        end
      end

      @archives = source_archives
      @scripts = source_scripts
    end
    
    render :update do |page|
        page.replace_html "links",:partial=>"assets/link_view",:locals=>{:archives=>@archives, :scripts=>@scripts}
    end
  end
    
#experimental code for doing jgrid table using jqgrid plugin
  def grid_view
    puts "doing some stuff"
    @query= params[:survey_search_query]
    datasets=params[:entry_ids]
    @dataset_request = ""
    datasets.each do |dataset|
      @dataset_request = @dataset_request + "&datasets[]=" + dataset
    end
  end

  def search_stuff
    puts "doing some stuff"
    @selected_surveys = params[:datasets]
    res = Variable.multi_solr_search(params[:query].downcase, :limit=>1000, :models=>(Variable))
    solr_docs = res.docs
    temp_variables = Array.new
    #    page_res = solr_docs.paginate(:page=>params[:page], :per_page=>params[:per_page])
    solr_docs.each do |item|
      @selected_surveys.each do |ids|
        if Dataset.find(item.dataset_id).id.to_s == ids
          logger.info("Found " + item.name + ", from Survey " + item.dataset_id.to_s)
          puts "Found " + item.name + ", from Survey " + item.dataset_id.to_s
          temp_variables.push(item)
          break
        end
      end
    end
    temp_variables.each do |var|
      var_name = var.name
      var.name = "<a href='/variables/" + var.id.to_s
      var.name = var.name + "'>"
      var.name = var.name + var_name
      var.name = var.name + "</a>"
    end
    page_res = temp_variables.paginate(:page=>params[:page], :per_page=>params[:rows])

    #    @variables = Variable.find(:all, :conditions=>"category='income'")
    #    start_value = (params[:page] - 1) * params[:rows]
    #    end_value = params[:page] * params[:rows]
    #    @paged_variables = Array.new
    #    if @variables
    #
    #    end
    #    for i in start_value..end_value
    #      @paged_variables.push(@variables[i])
    #    end
    #    @variables_json = page_res.to_jqgrid_json([:id,:name,:value,:category],params[:page],params[:rows],temp_variables.size)
    @variables_json = page_res.to_jqgrid_json([:name,:value,:category],params[:page],params[:rows],temp_variables.size)

    puts @variables_json
    respond_to do |format|
      format.html
      format.json { render :json => @variables_json }

    end

    #     respond_to do |format|
    #        logger.info("rendering grid view")
    #        format.html
    #        format.xml
    #      end
  end

  def search_variables
    do_search_variables
  end

  def index
    #@surveys=Authorization.authorize_collection("show",@surveys,current_user)

    @survey_hash = Hash.new
    @surveys.each do |survey|
      if (!@survey_hash.has_key?(survey.survey_type.shortname))
        @survey_hash[survey.survey_type.shortname] = Array.new
      end
      @survey_hash[survey.survey_type.shortname].push(survey)
    end
    puts @survey_hash

    @variables = Array.new
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml=>@surveys}
    end
  end

  def data

    results = Variable.find_by_solr("height",:limit => 1000).docs do
      paginate :page => params[:page], :per_page => params[:rows]
      order_by "#{params[:sidx]} #{params[:sord]}"
    end
    logger.info(results.to_jqgrid_json([:id,:name,:value,"survey.title"], params[:page], params[:rows], results.size))
    respond_to do |format|
      logger.info("rendering")
      format.html
      format.json {render :json => results.to_jqgrid_json([:name,:value,"survey.title","survey.survey_type.shortname"], params[:page], params[:rows], results.size)}
    end
  end

  def sort_variables
    @survey_search_query = params[:survey_search_query]
    @survey_list = params[:survey_list]

    @sorted_variables = params[:sorted_variables]
    @unsorted_vars = Array.new
    @sorted_variables.each do |var|
      @unsorted_vars.push(Variable.find(var))
    end

    case params['sort']
    when "variable"
      @sorted_variables = @unsorted_vars.sort_by { |m| m.name.upcase }
    when "dataset"
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).name.upcase }
    when "description"   then "description"
      @sorted_variables = @unsorted_vars.sort_by { |m| if m.value then m.value.upcase else "ZZZZ" end }
    when "category"   then "category"
      @sorted_variables = @unsorted_vars.sort_by { |m| if m.category then m.category.upcase else "ZZZZ" end }
    when "survey" then "survey"
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.survey_type.shortname.upcase }
    when "year" then "year"
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.year }
    when "popularity" then "popularity"
      @sorted_variables = @unsorted_vars.sort_by { |m| VariableList.all(:conditions=>"variable_id=" + m.id.to_s).size}
    when "variable_reverse"  then "variable DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| m.name.upcase }.reverse
    when "category_reverse"   then "category DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| if m.category then m.category.upcase else "ZZZZ" end }.reverse
    when "description_reverse"   then "description DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| if m.value then m.value.upcase else "ZZZZ" end }.reverse
    when "dataset_reverse"   then "dataset DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).name.upcase }.reverse
    when "survey_reverse" then "survey DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.survey_type.shortname.upcase }.reverse
    when "year_reverse" then "year DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.year }.reverse
    when "popularity_reverse" then "popularity DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| VariableList.all(:conditions=>"variable_id=" + m.id.to_s).size}.reverse
    end
    render :update, :status=>:created do |page|
      page.replace_html "table_header", :partial=>"surveys/table_header",:locals=>{:sorted_variables=>@sorted_variables}
      page.replace_html "table_container", :partial=>"surveys/table",:locals=>{:sorted_variables=>@sorted_variables}
    end
  end

  def more_info
    @div = params[:div_id]
    @item_id = params[:item_id]
    @curr_cycle = params[:curr_cycle]
    @item = Variable.find(@item_id)

    render :update, :status=>:created do |page|
      page.replace_html @div, :partial=>"surveys/variables_table_expanded_row",:locals=>{:curr_cycle=>@curr_cycle, :item => @item}
    end
  end

  def hide_info
    @div = params[:div_id]
    @item_id = params[:item_id]
    @curr_cycle = params[:curr_cycle]
    @item = Variable.find(@item_id)

    render :update, :status=>:created do |page|
      page.replace_html @div, :partial=>"surveys/variables_table_row",:locals=>{:curr_cycle=>@curr_cycle,:item => @item}
    end
  end

  def view_variables
    #    @surveys = Survey.find(params[:entry_ids])
    #    items_per_page = 10

    @variables = Array.new
    @survey_list = Array.new(params[:entry_ids])



    #    conditions = ["name LIKE ?", "%#{params[:query]}%"] unless params[:query].nil?

    #    @total = Survey.find(params[:entry_ids])
    #    @items_pages, @items = paginate :surveys, :order => sort, :per_page => items_per_page
    #    @variables.clear
    #    if request.xml_http_request?
    #      render :partial => "view_variables", :layout => false
    #    end

  end

  # DELETE /models/1
  # DELETE /models/1.xml
  def destroy
    #FIXME: Double check auth is working for deletion. Also, maybe should only delete if not associated with any assays.
    @survey.destroy

    respond_to do |format|
      format.html { redirect_to(surveys_url) }
      format.xml  { head :ok }
    end
  end

  #no auth for the moment,login is enough
  def new
    @survey_types =SurveyType.find(:all)
    
    respond_to do |format|
      # if Authorization.is_member?(current_user.person_id, nil, nil)
      format.html # new.html.erb
      #else
      # flash[:error] = "You are not authorized to upload new Surveys. Only members of known projects, institutions or work groups are allowed to create new content."
      #format.html { redirect_to surveys_path }
      #end
    end
  end

  def create
    
    if (params[:survey_type_name])!= "" && (params[:survey_type_shortname]) != ""
      s_type = SurveyType.new
      s_type.name = params[:survey_type_name]
      s_type.shortname = params[:survey_type_shortname]
      s_type.description = params[:survey_type_description]
      s_type.save
      params[:survey][:survey_type] = s_type
    else
      params[:survey][:survey_type] = SurveyType.find(params[:survey][:survey_type].to_i)
    end
    # if (params[:survey][:data]).blank?
    #   respond_to do |format|
    #     flash.now[:error] = "Please select a file to upload."
    #     format.html {
    #       set_parameters_for_sharing_form()
    #       render :action => "new"
    #     }
    #   end
    # elsif (params[:survey][:data]).size == 0
    #   respond_to do |format|
    #     flash.now[:error] = "The file that you have selected is empty. Please check your selection and try again!"
    #     format.html {
    #       set_parameters_for_sharing_form()
    #       render :action => "new"
    #     }
    #   end
    # else
      # create new Survey file and content blob - non-empty file was selected

      # prepare some extra metadata to store in Survey files instance
      params[:survey][:contributor_type] = "User"
      params[:survey][:contributor_id] = current_user.id


      # store properties and contents of the file temporarily and remove the latter from params[],
      # so that when saving main object params[] wouldn't contain the binary data anymore
      # params[:survey][:content_type] = (params[:survey][:data]).content_type
      # params[:survey][:original_filename] = (params[:survey][:data]).original_filename
      # data = params[:survey][:data].read
      # name = (params[:survey][:data]).original_filename
      # params[:survey].delete('data')

      # directory = "public/data"
      #      # create the file path
      #      path = File.join(directory, name)
      #      # write the file
      #      File.open(path, "wb") do |f|
      #        f.write(data)
      #      end


      # store source and quality of the new Survey file (this will be kept in the corresponding asset object eventually)
      # TODO set these values to something more meaningful, if required for Survey files
      # params[:survey][:source_type] = "upload"
      #      params[:survey][:source_id] = nil
      #      params[:survey][:quality] = nil


      @survey = Survey.new(params[:survey])

        #      @survey.content_blob = ContentBlob.new(:data => data)

      respond_to do |format|
        if @survey.save
          # the Survey file was saved successfully, now need to apply policy / permissions settings to it
          policy_err_msg = Policy.create_or_update_policy(@survey, current_user, params)

          # update attributions
          Relationship.create_or_update_attributions(@survey, params[:attributions])

          if policy_err_msg.blank?
            flash[:notice] = 'Survey was successfully uploaded and saved.'
            format.html { redirect_to survey_path(@survey) }
          else
            flash[:notice] = "Survey was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
            format.html { redirect_to :controller => 'surveys', :id => @survey, :action => "edit" }
          end
        else
          format.html {
            set_parameters_for_sharing_form()
            render :action => "new"
          }
        end
      end
    # end
  end

  def show
    # store timestamp of the previous last usage
    #    @last_used_before_now = @survey.last_used_at

    # update timestamp in the current Survey file record
    # (this will also trigger timestamp update in the corresponding Asset)
    #    @survey.last_used_at = Time.now
    #    @survey.save_without_timestamping

    # @survey = Survey.find(params[:id])
    @forum = Forum.all(:conditions=>["name=?", @survey.title])[0]

    source_archives = []
    source_scripts = []
    # no survey link to publications yet, maybe in the future
    # source_publications = []

    links = Link.find(:all, :conditions => { :object_type => "Survey", :object_id => @survey.id, :predicate => "link" })

    links.each do |link|
      case link.subject.class.name
      when "Csvarchive"
        source_archives.push(link.subject)
      when "Script"
        source_scripts.push(link.subject)
      # when "Publication"
      #         source_publications.push(link.subject)
      end
    end

    @archives = source_archives
    @scripts = source_scripts
    
    find_all_categories_for_survey
    # @publications = source_publications

    respond_to do |format|
      format.html # show.html.erb
      format.xml {render :xml=>@survey}
    end
  end

  def edit
    if !current_user.is_admin?
      flash[:error] = 'You do not have permission to edit survey metadata.'
      respond_to do |format|
        format.html { redirect_to survey_path(@survey) }
      end
    else
      respond_to do |format|
        format.html # edit.html.erb
        format.xml
      end
    end

  end

  def update
    if !current_user.is_admin?
      flash[:error] = 'You do not have permission to edit survey metadata.'
      respond_to do |format|
        format.html { redirect_to survey_path(@survey) }
      end
    else
    # remove protected columns (including a "link" to content blob - actual data cannot be updated!)
    if params[:survey]
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at].each do |column_name|
        params[:survey].delete(column_name)
      end

      # update 'last_used_at' timestamp on the Survey
      params[:survey][:last_used_at] = Time.now

      # update 'contributor' of the Survey file to current user (this under no circumstances should update
      # 'contributor' of the corresponding Asset: 'contributor' of the Asset is the "owner" of this
      # Survey, e.g. the original uploader who has unique rights to manage this Survey; 'contributor' of the
      # Survey file on the other hand is merely the last user to edit it)
      params[:survey][:contributor_type] = current_user.class.name
      params[:survey][:contributor_id] = current_user.id
    end

    respond_to do |format|
      if @survey.update_attributes(params[:survey])
        # the Survey file was updated successfully, now need to apply updated policy / permissions settings to it
        policy_err_msg = Policy.create_or_update_policy(@survey, current_user, params)

        # update attributions
        Relationship.create_or_update_attributions(@survey, params[:attributions])

        if policy_err_msg.blank?
          flash[:notice] = 'Survey file metadata was successfully updated.'
          format.html { redirect_to survey_path(@survey) }
        else
          flash[:notice] = "Survey file metadata was successfully updated. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
          format.html { redirect_to :controller => 'surveys', :id => @survey, :action => "edit" }
        end
      else
        format.html {
          set_parameters_for_sharing_form()
          render :action => "edit"
        }
      end
    end
  end
  end

  # GET /sops/1;download
  def download
    # update timestamp in the current SOP record
    # (this will also trigger timestamp update in the corresponding Asset)
    @survey.last_used_at = Time.now
    @survey.save_without_timestamping

    send_data @survey.content_blob.data, :filename => @survey.original_filename, :content_type => @survey.content_type, :disposition => 'attachment'
  end

  def survey_preview_ajax

    if params[:id] && params[:id]!="0"
      @survey = Survey.find(params[:id])
    end

    render :update do |page|
      if @survey && Authorization.is_authorized?("show", nil, @survey, current_user)
        page.replace_html "survey_preview",:partial=>"assets/resource_preview",:locals=>{:resource=>@survey}
      else
        page.replace_html "survey_preview",:text=>"No Survey file is selected, or authorised to show."
      end
    end
  end

  protected

  def find_previous_searches
    search=[]
    if logged_in?
      search = UserSearch.all(:order => "created_at DESC", :limit => 5, :conditions => { :user_id => current_user.id})
    end
    @recent_searches = search
  end

  #find any previous searches if you are looking at your own
  #profile
  def find_previous_searches
    search=[]
    if logged_in?
      search = UserSearch.all(:order => "created_at DESC", :limit =>10, :conditions => { :user_id => current_user.id})
    end
    @recent_searches = search
  end

  def find_survey
        @survey = Survey.find(params[:id])
  end

  def find_surveys
    found = Survey.find(:all,
      :order => "title")

    # this is only to make sure that actual binary data isn't sent if download is not
    # allowed - this is to increase security & speed of page rendering;
    # further authorization will be done for each item when collection is rendered
    #    found.each do |survey|
    #      survey.content_blob.data = nil unless Authorization.is_authorized?("download", nil, survey, current_user)
    #    end

    @surveys = found
  end


  def find_survey_auth
    begin
      action=action_name

      survey = Survey.find(params[:id])

      if Authorization.is_authorized?(action_name, nil, survey, current_user)
        @survey = survey
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to surveys_path }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the Survey file or you are not authorized to view it"
        format.html { redirect_to surveys_path }
      end
      return false
    end
  end

  def set_parameters_for_sharing_form
    policy = nil
    policy_type = ""

    # obtain a policy to use
    if defined?(@survey) && @survey.asset
      if (policy = @survey.asset.policy)
        # Surveyfile exists and has a policy associated with it - normal case
        policy_type = "asset"
      elsif @survey.asset.project && (policy = @survey.asset.project.default_policy)
        # Surveyfile exists, but policy not attached - try to use project default policy, if exists
        policy_type = "project"
      end
    end

    unless policy
      # several scenarios could lead to this point:
      # 1) this is a "new" action - no Surveyfile exists yet; use default policy:
      #    - if current user is associated with only one project - use that project's default policy;
      #    - if current user is associated with many projects - use system default one;
      # 2) this is "edit" action - Surveyfile exists, but policy wasn't attached to it;
      #    (also, Surveyfile wasn't attached to a project or that project didn't have a default policy) --
      #    hence, try to obtain a default policy for the contributor (i.e. owner of the Surveyfile) OR system default
      projects = current_user.person.projects
      if projects.length == 1 && (proj_default = projects[0].default_policy)
        policy = proj_default
        policy_type = "project"
      else
        policy = Policy.default(current_user)
        policy_type = "system"
      end
    end

    # set the parameters
    # ..from policy
    @policy = policy
    @policy_type = policy_type
    @sharing_mode = policy.sharing_scope
    @access_mode = policy.access_type
    @use_custom_sharing = (policy.use_custom_sharing == true || policy.use_custom_sharing == 1)
    @use_whitelist = (policy.use_whitelist == true || policy.use_whitelist == 1)
    @use_blacklist = (policy.use_blacklist == true || policy.use_blacklist == 1)

    # ..other
    @resource_type = "Survey"
    @favourite_groups = current_user.favourite_groups

    @all_people_as_json = Person.get_all_as_json
  end

  def check_search_parameters
    search_query = params[:survey_search_query]
    if !params[:survey_search_query] or params[:survey_search_query].length == 0 or params[:survey_search_query] == "Enter search terms"
      error = "Searching requires a term to be entered in the survey search box."
    elsif !params[:entry_ids] or params[:entry_ids].size == 0
      error = "Searching requires at least one survey/dataset selected."
    else
      dataset = Dataset.find_all_by_id(params[:entry_ids])
      if dataset.length == params[:entry_ids].length
        return true
      else
        error = "Incorrect dataset included. Please contact an admin if this reoccurs."
      end
    end
    respond_to do |format|
      flash[:error] = error
      format.html { redirect_to :action=>:index, :survey_search_query => search_query }
    end
    return false
  end

 private 

  def do_search_variables
    @survey_search_query = params[:survey_search_query]

    #save only new search terms
    new_search_terms = @survey_search_query.downcase.split(' or ')
    #Check that the same term has been included twice by combining searches
    new_search_terms.uniq!
    new_search_terms.each do |search_term|
      unless SearchTerm.find(:first, :conditions=>["term=?",search_term])
        t = SearchTerm.new
        t.term = search_term
        t.save
      end
    end

    case params['add_results']
      when "yes"
        @survey_search_query = @survey_search_query + " or " +params[:previous_query]
      when "no"
        #don't have to do anything
    end
      
    @selected_surveys = Array.new(params[:entry_ids])
    @vars_by_dataset = Hash.new
    @selected_surveys.each do |dataset|
        @vars_by_dataset[dataset] = 0
      end
    @total_vars = 0
  
    @search_terms = @survey_search_query.downcase.split(' or ')
    @search_terms.uniq!
      
    @sorted_variables = Array.new
    @term_results = Hash.new

    @search_terms.each do |term|
      @term_results[term] = Array.new
      @selected_surveys.each do |ids|
        logger.info("searching for " + term)
        variables = find_variables(term, ids)
        logger.info("found "+variables.length.to_s)
        variables.each do | variable |
          @term_results[term].push(variable) 
          if !@sorted_variables.include?(variable)
            @sorted_variables.push(variable)
            #ogger.info("variable.dataset_id = "+variable.dataset_id.to_s)
            #ogger.info("@vars_by_dataset[variable.dataset_id] = "+@vars_by_dataset[variable.dataset_id.to_s].to_s)
            @vars_by_dataset[variable.dataset_id.to_s]+= 1
            @total_vars+= 1
          end  
        end  
      end
      if logged_in? && new_search_terms.include?(term)
      #TODO There must be a way to avoid duplicating the save if the search is repeated.
        user_search = UserSearch.new
        user_search.user = current_user
        user_search.terms = term
        user_search.dataset_ids = @selected_surveys
        var_as_ints = Array.new
        @sorted_variables.each do |temp_var|
          var_as_ints.push(temp_var.id)
        end
        user_search.variable_ids = var_as_ints
        user_search.save
      end   
      
    end #search_terms.each do |term|

    respond_to do |format|
      logger.info("rendering survey search")
      format.html { render :action =>:search_variables }
      format.xml  { render :xml =>:search_variables }
    end
  end

  def rerouted_search
    if "search_variables".eql?(params[:id])
      params[:entry_ids] = params[:entry_ids].split(',')
      find_surveys
      check_search_parameters
      do_search_variables
      #respond_to do |format|
      #  format.html do
      #    store_location
      #    if session[:return_to] != root_path
      #      flash[:message] = "Please reenter your search"
      #    end
      #    redirect_to surveys_path
      #  end
      #end
       #return false
       #params[:entry_ids] = params[:entry_ids].split(',')
       ##params[:survey_search_query] = "beer"
       #bad = bad + 2
       #action = search_variables
     else
	return true
     end
   end

   #Note !SOLR_ENABLED is for testing purposes only and will not give as many results as SOLR_ENABLED
   def find_variables(term, dataset)
     if (SOLR_ENABLED)
        query = term + " AND dataset_id:" + dataset.to_s
        results = Variable.find_by_solr(query, :limit => 1000)
        results.docs
      else
        results = Variable.find(:all, :conditions => ["name like ? or value like ?", '%'+term+'%','%'+term+'%'])
      end
    end
    
    #new - not tested via ui yet
    #Load a new CSV/Tabbed file for a survey.
    #Create the dataset and the variables from the header line
    def load_new_dataset file, survey, dataset_name
      dataset = Dataset.new
      dataset.survey = survey
      dataset.name = dataset_name
      dataset.save
      header = File.open(file) {|f| f.readline}
      #split by tab
      headers = header.split("\t")
      headers.each do |var|
        variable = Variable.new
        variable.name = name
        variable.dataset = dataset
        variable.save
      end
      
      #TODO - push the file over to the CSV server (or just copy it to a directory somewhere?!?)
      
    end
    
    #new - not tested via ui yet
    #Read the metadata from a ccsr type xml file for a particular survey
    def read_ccsr_metadata file,dataset_id
      
      data = file.read
      parser = XML::Parser.io(file, :encoding => XML::Encoding::ISO_8859_1)
      doc = parser.parse

        nodes = doc.find('//ccsrmetadata/variables')
        # doc.close

        nodes[0].each_element do |node|
          if (/^id_/.match(node.name)) 
            name = node["variable_name"]
            label = node["variable_label"]
            puts name + " " + label
            value_map = String.new
            node.each_element do |child_node| 
              if (!child_node.empty?) 
                value_map <<  "value " + child_node["value"] + " label " + child_node["value_name"] + "\r\n"
              end
            end
            variable = Variable.new
                     variable.name = name
                     variable.value= label
            #          variable.dertype = variable_dertype
            #          variable.dermethod = variable_dermethod
                     variable.info = value_map
            #          variable.category = variable_category
                     variable.dataset_id = dataset_id;
            #          variable.page = page
            #          variable.document = document
                     variable.save
            end
          end
          
    end
    
    #find the variable categories for a specific survey (@survey)
    def find_all_categories_for_survey
      ["#{Monitorship.table_name}.user_id = ? and #{Post.table_name}.user_id != ? and #{Monitorship.table_name}.active = ?", params[:user_id], @user.id, true]
       inner join Surveys on Surveys.dataset#{Monitorship.table_name} on #{Monitorship.table_name}.topic_id = #{Topic.table_name}.id"
      @all_categories = []
      @survey.datasets.each do |dataset|
        cats = Variable.all(:select => "DISTINCT(category)",:conditions=>({:dataset_id => dataset.id}))
        cats.each do |var|
          @all_categories << var.category
        end
      end
      @all_categories.uniq!
      @all_categories.sort!
    end
    
    #find the variable categories for all surveys with a survey_type
    def find_all_categories survey_type_id
      # @all_categories = Variable.all(:select => "DISTINCT(category)",:conditions=>({:dataset.survey_type_id => survey_type_id}), :joins=>:dataset)
      categories = Variable.find_by_sql("select distinct(variables.category) from variables, datasets, surveys, survey_types where variables.dataset_id = datasets.id and datasets.survey_id = surveys.id and surveys.survey_type_id = #{survey_type_id}")
      @all_categories = categories.collect{|var| var.category}
      @all_categories.delete_if{|cat| cat==nil}
      @all_categories.sort!
    end

end
