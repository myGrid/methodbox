class SurveysController < ApplicationController
  
  # before_filter :is_user_admin_auth, :only =>[ :new, :create]

  before_filter :login_required, :except => [ :help, :help2, :index, :search_variables, :sort_variables, :show, :facets, :category_browse, :show_datasets_for_categories]
  
  before_filter :find_previous_searches, :only => [ :index]

  before_filter :find_surveys, :only => [ :index, :search_variables ]

  before_filter :find_previous_searches, :only => [ :index ]

  #before_filter :find_survey_auth, :except => [ :index, :new, :create,:survey_preview_ajax, :help ]
  
  before_filter :find_survey, :only => [:show, :edit, :update]

  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]

  before_filter :check_search_parameters, :only => [:search_variables]

  before_filter :rerouted_search, :only => [:show]
  
  before_filter :find_groups, :only => [ :new, :edit ]
  
  before_filter :find_comments, :only => [ :show ]

  before_filter :find_notes, :only => [ :show ]
  
  after_filter :update_last_user_activity
  
  #list of surveys to add to the db
  def add_nesstar_surveys
    respond_to do |format|
      begin
        Delayed::Job.enqueue AddNesstarSurveysJob::StartJobTask.new(params[:datasets], params[:nesstar_url], params[:nesstar_catalog], current_user.id, base_host)
        flash[:notice] = "Surveys are being added to MethodBox.  You will receive an email when it is complete."
      rescue Exception => e
        flash[:error] = "There was a problem adding the datasets. Please try again later."
        puts e
      ensure
        format.html {redirect_to surveys_url}
      end
    end
  end
  
  #retrieve list of catalogs from a nesstar server
  def new_nesstar_datasource
    @nesstar_url = params[:nesstar_url]
    @nesstar_catalog = params[:nesstar_catalog]
    nesstar_api = Nesstar::Api::CatalogApi.new
    nodes = nesstar_api.get_nodes(@nesstar_url, @nesstar_catalog)
    @survey_types = Hash.new
    @surveys = Hash.new
    @datasets = Hash.new
    begin
      nesstar_api.parse_surveys_from_nodes nodes.root, @surveys, @survey_types
      # @surveys.each_key do |survey|
      #   @surveys[survey].each do |dataset|
      #     info = nesstar_api.get_simple_study_information @nesstar_url, dataset.split('/').last
      #     @datasets[dataset] = info.title
      #   end
      # end
    rescue Exception => e
      respond_to do |format|
        flash[:error] = "There seems to be problems with the nesstar server.  Please try again later."
        format.html {redirect_to surveys_url}
      end
    end
    # render :update, :status=>:created do |page|
    #   page.replace_html "nesstar-survey-table", :partial => "nesstar_surveys", :locals=>{:surveys => surveys, :survey_types => survey_types}
    # end
  end
  
  #entry route to add a catalog
  def nesstar_datasource
    
  end
  
  #find all the variables for a particular survey
  def show_all_variables
    @survey = Survey.find(params[:id])
    variables = []
    @survey.datasets.each do |dataset|
      variables += dataset.variables
    end
    render :update, :status=>:created do |page|
      page.replace_html "variables-table", :partial => "show_all_vars_for_survey", :locals=>{:sorted_variables => variables}
    end
  end
  
  #a users notes about a resource
  def add_note
    @survey = Survey.find(params[:resource_id])
    note = Note.new(:words=>params[:words], :user_id=>current_user.id, :notable_id=>@survey.id, :notable_type=>"Survey")
    note.save
    render :partial=>"notes/note", :locals=>{:note=>note}
  end

  #add a user owned comment to a script and add it to the view
  def add_comment
    @survey = Survey.find(params[:resource_id])
    comment = Comment.new(:words=>params[:words], :user_id=>current_user.id, :commentable_id=>@survey.id, :commentable_type=>"Survey")
    comment.save
    render :partial=>"comments/comment", :locals=>{:comment=>comment}
  end
  
  #ajax remote for displaying the surveys for a specific survey type
  def show_datasets_for_categories
    survey_type = SurveyType.find(params[:survey_type_id])
    @surveys= Survey.all(:conditions=>({:survey_type_id=>survey_type.id}))
    @surveys.reject! {|survey| !Authorization.is_authorized?("show", nil, survey, current_user)}
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
  def facets
    @surveys_json = "{types:{\"Dataset\":{pluralLabel:\"Datasets\"}},"
    @surveys_json << "\"items\":["
    Survey.all.each do |survey|
      unless !Authorization.is_authorized?("show", nil, survey, current_user)
           # @surveys_json << "{\"label\":\"" + survey.title + "\",\"year\":\"" + survey.year + "\",\"type\" : \"Survey\",\"survey_description\" :\"" + survey.description
          #        @surveys_json << "\",\"survey_type\":\"" + survey.survey_type.shortname + "\"},"
        survey.datasets.each do |dataset|
          @surveys_json << "{\"label\":\"" + dataset.id.to_s + "\",\"name\":" + dataset.name.to_json + ",\"survey-type\":" + survey.survey_type.shortname.to_json + ",\"year\":\"" + survey.year + "\",\"type\" : \"Dataset\",\"dataset-description\" :" + dataset.description.to_json
          @surveys_json << ",\"Survey\":" + survey.title.to_json + ",\"survey-description\" :" + survey.description.to_json + "},"
        end
      end
    end
    @surveys_json.chop!
    @surveys_json << "]}"
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

# list all the surveys that the current user can see.
  def index
    #@surveys=Authorization.authorize_collection("show",@surveys,current_user)
    # if current_user != nil
    #   @ukda_registered = ukda_registration_check(current_user)
    # else
    #   @ukda_registered = false
    # end
    @survey_hash = Hash.new
    @empty_surveys = []
    @surveys.each do |survey|
      unless survey.datasets.empty? 
        unless !Authorization.is_authorized?("show", nil, survey, current_user)
      # unless survey.survey_type.is_ukda && !@ukda_registered
          if (!@survey_hash.has_key?(survey.survey_type.shortname))
            @survey_hash[survey.survey_type.shortname] = Array.new
          end
          @survey_hash[survey.survey_type.shortname].push(survey)
        end
    # end
      else
        @empty_surveys.push(survey) unless !Authorization.is_authorized?("show", nil, survey, current_user)
      end
    end
    puts @survey_hash

    @variables = Array.new

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml=>@surveys}
      #FIXME some sort of bug causes the first character in the xml type declaration to be
      #stripped off before the rdf+xml transfer, this <?xml version="1.0" encoding="UTF-8"?>
      #becomes ?xml version="1.0" encoding="UTF-8"?>
      format.rdf { render :layout => false, :content_type => 'application/rdf+xml' }
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
      page.replace_html "table_container", :partial=>"surveys/table",:locals=>{:sorted_variables=>@sorted_variables,:lineage => false, :extract_lineage => false, :extract_id => nil}
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
    @ukda_only = false
    @survey_types =SurveyType.all
    if !current_user.is_admin
      @survey_types.reject!{|survey_type| survey_type.is_ukda }
    end
    
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
      if params[:ukda_survey] == "yes"
        s_type.is_ukda = true
      else
        s_type.is_ukda = false
      end
      s_type.save
      params[:survey][:survey_type] = s_type
      forum = Forum.new()
      forum.name = s_type.shortname
      forum.description = "Questions about " + s_type.name
      forum.position = 4
      forum.save
    else
      params[:survey][:survey_type] = SurveyType.find(params[:survey][:survey_type].to_i)
    end
      # prepare some extra metadata to store in Survey files instance
      params[:survey][:contributor_type] = "User"
      params[:survey][:contributor_id] = current_user.id


      @survey = Survey.new(params[:survey])
       
      respond_to do |format|
        if @survey.save
           policy = Policy.create(:name => "survey_policy", :sharing_scope => params[:sharing][:sharing_scope], :use_custom_sharing => params[:sharing][:sharing_scope] == Policy::CUSTOM_PERMISSIONS_ONLY.to_s ? true : false, :access_type => 2, :contributor => current_user)
            @survey.asset.policy = policy
            policy.save
            @survey.asset.save
            if params[:groups] != nil && params[:sharing][:sharing_scope] == Policy::CUSTOM_PERMISSIONS_ONLY.to_s
              params[:groups].each do |workgroup_id|
                policy.permissions << Permission.create(:contributor_id => workgroup_id, :contributor_type => "WorkGroup", :policy => policy, :access_type => 2)
              end
            end

          # update attributions
          Relationship.create_or_update_attributions(@survey, params[:attributions])

          flash[:notice] = 'Survey was successfully uploaded and saved.'
          format.html { redirect_to survey_path(@survey) }
        else
          format.html {
            set_parameters_for_sharing_form()
            render :action => "new"
          }
        end
      end
  end

  def show
    unless !Authorization.is_authorized?("show", nil, @survey, current_user)
    # store timestamp of the previous last usage
    #    @last_used_before_now = @survey.last_used_at

    # update timestamp in the current Survey file record
    # (this will also trigger timestamp update in the corresponding Asset)
    #    @survey.last_used_at = Time.now
    #    @survey.save_without_timestamping

    # @survey = Survey.find(params[:id])
    @forum = Forum.all(:conditions=>["name=?", @survey.survey_type.shortname])[0]

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
  else
    flash[:error] = "You do not have permission to carry out that action"
    respond_to do |format|
      format.html { redirect_to surveys_url }
    end
  end
  end

  def edit
    @survey = Survey.find(params[:id])
    if Authorization.is_authorized?("edit", nil, @survey, current_user) || (current_user && @survey.survey_type.is_ukda && current_user.is_admin?)
      @selected_groups = []
      @ukda_only = @survey.survey_type.is_ukda
      @survey_types =SurveyType.all
      if !current_user.is_admin
        @survey_types.reject!{|survey_type| survey_type.is_ukda }
      end
      if @survey.asset.policy.get_settings["sharing_scope"] == Policy::CUSTOM_PERMISSIONS_ONLY
        @sharing_mode = Policy::CUSTOM_PERMISSIONS_ONLY
        @survey.asset.policy.permissions.each do |permission|
          if permission.contributor_type == "WorkGroup"
            @selected_groups.push(permission.contributor_id)
          end
        end
      end
      respond_to do |format|
        format.html # edit.html.erb
        format.xml
      end
      
    else
      flash[:error] = 'You do not have permission to edit survey metadata.'
      respond_to do |format|
        format.html { redirect_to survey_path(@survey) }
      end
    end

  end

  def update
    if !Authorization.is_authorized?("edit", nil, @survey, current_user) || !current_user || @survey.survey_type.is_ukda && !current_user.is_admin?
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
    
     #clear any custom permissions
     if @survey.asset.policy.use_custom_sharing 
       @survey.asset.policy.permissions.clear
     end
     @survey.asset.policy.update_attributes(:sharing_scope => params[:sharing][:sharing_scope], :use_custom_sharing => params[:sharing][:sharing_scope] == Policy::CUSTOM_PERMISSIONS_ONLY.to_s ? true : false)

     if params[:groups] != nil && params[:sharing][:sharing_scope] == Policy::CUSTOM_PERMISSIONS_ONLY.to_s
       params[:groups].each do |workgroup_id|
         @survey.asset.policy.permissions << Permission.create(:contributor_id => workgroup_id, :contributor_type => "WorkGroup", :policy => @survey.asset.policy, :access_type => 2)
       end
     end
     
    respond_to do |format|
      if @survey.update_attributes(params[:survey])

        # update attributions
        Relationship.create_or_update_attributions(@survey, params[:attributions])

          flash[:notice] = 'Survey file metadata was successfully updated.'
          format.html { redirect_to survey_path(@survey) }
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
      action=action_name

      survey = Survey.find(params[:id])

      return Authorization.is_authorized?(action_name, nil, survey, current_user)
  end

  def set_parameters_for_sharing_form
    policy = nil
    policy_type = "survey_policy"
    # @survey = Survey.find(params[:id])

    # # obtain a policy to use
    if defined?(@survey) && @survey.asset
      if (policy = @survey.asset.policy)
    #     # Surveyfile exists and has a policy associated with it - normal case
    #     puts "we have a policy"
        policy_type = "survey_policy"
    #   elsif @survey.asset.project && (policy = @survey.asset.project.default_policy)
    #     # Surveyfile exists, but policy not attached - try to use project default policy, if exists
    #     policy_type = "project"
      end
    end
    # 


    # set the parameters
    # ..from policy
    # policy = @survey.asset.policy
    unless policy
      puts "there is no policy"
      # several scenarios could lead to this point:
      # 1) this is a "new" action - no Surveyfile exists yet; use default policy:
      #    - if current user is associated with only one project - use that project's default policy;
      #    - if current user is associated with many projects - use system default one;
      # 2) this is "edit" action - Surveyfile exists, but policy wasn't attached to it;
      #    (also, Surveyfile wasn't attached to a project or that project didn't have a default policy) --
      #    hence, try to obtain a default policy for the contributor (i.e. owner of the Surveyfile) OR system default

        policy = Policy.default(current_user)
        policy_type = "survey_policy"
    end
    @policy = policy
    @policy_type = policy_type
    @sharing_mode = policy.sharing_scope
    puts "sharing mode is " + policy.sharing_scope.to_s
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
      format.html { redirect_to :back, :survey_search_query => search_query }
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
      @all_categories = []
      @survey.datasets.each do |dataset|
        cats = Variable.all(:select => "DISTINCT(category)",:conditions=>({:dataset_id => dataset.id}))
        cats.each do |var|
          @all_categories << var.category unless var.category == nil
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
    
    def find_groups
      @groups = WorkGroup.all
    end
    
    #find all the comments for this data extract
    def find_comments
      survey =Survey.find(params[:id])
      @comments = survey.comments
    end
    
    def find_notes
      if current_user
        @survey =Survey.find(params[:id])
        @notes = Note.all(:conditions=>{:notable_type => "Survey", :user_id=>current_user.id, :notable_id => @survey.id})
      end
    end

end
