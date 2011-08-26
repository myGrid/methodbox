class SurveysController < ApplicationController
  
  before_filter :login_required, :except => [ :show_all_variables, :retrieve_details, :help, :help2, :index, :search_variables, :sort_variables, :show, :facets, :category_browse, :show_datasets_for_categories, :collapse_row, :expand_row]
  
  before_filter :find_previous_searches, :only => [ :index, :show ]

  before_filter :find_surveys, :only => [ :index, :search_variables ]
  
  before_filter :find_survey, :only => [:show, :edit, :update]

  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]

  before_filter :check_search_parameters, :only => [:search_variables]

  before_filter :rerouted_search, :only => [:show]
  
  before_filter :find_groups, :only => [ :new_nesstar_datasource, :new, :edit ]
  
  before_filter :find_comments, :only => [ :show ]

  before_filter :find_notes, :only => [ :show ]
  
  after_filter :update_last_user_activity

  caches_action :collapse_row, :expand_row
  
  def retrieve_details
    @survey = Survey.find(params[:survey_id])
    render :partial => 'survey_table_row'
  end
  #After the user clicks on the 'collapse' for a row in the variable table
  def collapse_row
    variable = Variable.find(params[:id])
    item = variable
    row_name = item.id.to_s
    dataset = Dataset.find(params[:dataset])
    render :partial => 'variables_table_row', :locals=>{:item=>item,:row_name=>row_name, :curr_cycle=>params[:curr_cycle], :dataset=>dataset,:popularity=>params[:popularity], :id=>params[:id], :extract_lineage=>params[:extract_lineage], :extract_id=>params[:extract_id], :lineage=>params[:lineage]}
  end
  #After the user clicks on the drop down for a variable row
  def expand_row
    variable = Variable.find(params[:id])
    item = variable
    row_name = item.id.to_s
    dataset = variable.dataset
    value_domain_hash = Hash.new
    var_hash = Hash.new
    no_var_hash = Hash.new
    blank_rows = nil
    invalid_entries = nil
    total_entries = nil
    valid_entries = nil
    if variable.nesstar_id
	variable.value_domains.each do |value_domain|
	  if value_domain.value_domain_statistic
	    var_hash[value_domain.id] = value_domain.value_domain_statistic.frequency
	  end
	  value_domain_hash[value_domain.id] = value_domain.label
	end
	valid_entries = variable.valid_entries
	invalid_entries = variable.invalid_entries
        if valid_entries == nil
          total_entries = invalid_entries
        elsif invalid_entries == nil
         total_entries = valid_entries
        else
          total_entries = invalid_entries + valid_entries
        end
    else
      no_var_hash = variable.none_values_hash
      var_hash = variable.values_hash
      value_domain_hash = Hash.new
      var_hash.each_key do |key|
        variable.value_domains.each do |value_domain|
	  if value_domain.value.to_i.eql?(key.to_i)
	    value_domain_hash[key] = value_domain.label
	    break
	  end
	end
      end
      blank_rows = variable.number_of_blank_rows
      invalid_entries = 0
      no_var_hash.each_key do |key|
        variable.value_domains.each do |value_domain|
	  if value_domain.value.to_i.eql?(key.to_i)
	    value_domain_hash[key] = value_domain.label
	    break
	  else
	    value_domain_hash[key] = key
	  end
	end
	invalid_entries += no_var_hash[key]
      end
      valid_entries = 0
      var_hash.each_key do |key|
        valid_entries += var_hash[key]
      end
      no_var_hash.each_key do |key|
        valid_entries += var_hash[key]
      end
        if valid_entries == nil
          total_entries = invalid_entries
        elsif invalid_entries == nil
         total_entries = valid_entries
        else
          total_entries = invalid_entries + valid_entries
        end
      if blank_rows != nil
        total_entries += blank_rows
      end
#If there are no values then see if the value domains have any frequency stats - relevant to vars from nesstar ddi datasets
      if var_hash.empty?
        variable.value_domains.each do |value_domain|
	  if value_domain.value_domain_statistic
	    if value_domain.value_domain_statistic
	      var_hash[value_domain.value] = value_domain.value_domain_statistic.frequency
	    end
	    value_domain_hash[value_domain.value] = value_domain.label
	  end
	end
      end
    end
    render :partial => 'variables_table_expanded_row', :locals=>{:value_domain_hash => value_domain_hash, :valid_entries => valid_entries, :blank_rows => blank_rows, :total_entries => total_entries, :invalid_entries => invalid_entries, :var_hash => var_hash, :no_var_hash => no_var_hash, :hidden=>false, :item=>item,:row_name=>row_name, :curr_cycle=>params[:curr_cycle], :dataset=>dataset,:popularity=>params[:popularity], :id=>params[:id], :extract_lineage=>params[:extract_lineage], :extract_id=>params[:extract_id], :lineage=>params[:lineage]}
  end
  
  #list of surveys to add to the db
  def add_nesstar_surveys
    #expire_action :action=>"index"
    respond_to do |format|
      begin
        Delayed::Job.enqueue AddNesstarSurveysJob::StartJobTask.new(params[:datasets], params[:nesstar_url], params[:nesstar_catalog], params[:groups], params[:sharing_scope], current_user.id, base_host)
        flash[:notice] = "Surveys are being added to MethodBox.  You will receive an email when it is complete."
      rescue Exception => e
        flash[:error] = "There was a problem adding the datasets. Please try again later."
        logger.error Time.now.to_s + ", There was a problem adding the datasets. Please try again later. " + e
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
    rescue Exception => e
      respond_to do |format|
        flash[:error] = "There seems to be problems with the nesstar server.  Please try again later."
        format.html {redirect_to surveys_url}
      end
    end

  end
  
  #entry route to add a catalog
  def nesstar_datasource
    
  end
  
  #find all the variables for a particular survey
  def show_all_variables
    @survey = Survey.find(params[:id])
    page = params[:page] ? params[:page] : 1
    start_index = ((page.to_i - 1) * 50) + 1
    variables = []
    datasets = Dataset.all(:conditions => {:survey_id => @survey.id})
    variables = Variable.paginate(:order=>"name ASC", :conditions => {:dataset_id=> datasets}, :page => page, :per_page => 50)
    variables_hash = {"start_index"=>start_index, "page"=>page,"total_entries"=>variables.total_entries, "results" => variables.collect{|variable| {"id" => variable.id, "name"=> variable.name, "description"=>variable.value, "survey"=>variable.dataset.survey.title, "year"=>variable.dataset.survey.year, "category"=>variable.category, "popularity" => VariableList.all(:conditions=>"variable_id=" + variable.id.to_s).size}}}
    #@variables_json = variables_hash.to_json
    @selected_datasets = datasets
    @sorted_variables = variables
    respond_to do |format|
      format.html
      format.json {render :layout => false, :json=>variables_hash.to_json}
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
    all_surveys= Survey.all(:conditions=>({:survey_type_id=>survey_type.id}))
    all_surveys.reject! {|survey| !Authorization.is_authorized?("show", nil, survey, current_user)}
    all_categories = find_all_categories survey_type.id

    render :update, :status=>:created do |page|
      page.replace_html "categories", :partial=>"surveys/survey_categories", :locals => {:survey_type => survey_type, :surveys => all_surveys, :all_categories => all_categories}
    end
  end
  
  #display all the different survey types
  def category_browse
    @sorted_variables = []
    #@survey_types = SurveyType.all
    @survey_types = SurveyType.all(:conditions=>{:name=>["Research Datasets", "Teaching Datasets","Health Survey for England","General Household Survey"]})
    non_empty_survey_types = []
    @survey_types.each do |survey_type|
      any_datasets = false
      survey_type.surveys.each do |survey|
        any_datasets = true unless survey.datasets.empty?
      end
      if any_datasets 
        non_empty_survey_types << survey_type
      end
    end
    @survey_types = non_empty_survey_types
    var = nil
    @survey_types.each do |survey_type|
      survey_type.surveys.each do |survey|
        survey.datasets.each do |dataset|
          var = Variable.first(:all, :conditions => ["dataset_id =? and category is not ?", dataset.id, nil])
          if var != nil
            break
          end
        end
        if var != nil
          break
        end
      end
      if var != nil
        break
      end
    end
    #TODO this assumes that there will be a category somewhere for a variable
    if var != nil
      @selected_survey = var.dataset.survey
    end
    if var != nil
      @categories = find_all_categories @selected_survey.survey_type.id
    end

    @surveys = Survey.all(:conditions=>({:survey_type_id=>@selected_survey.survey_type.id}))
    @surveys.reject! {|survey| !Authorization.is_authorized?("show", nil, survey, current_user)}
  end
  
  # browse surveys using exhibit
  def facets
    survey_types = SurveyType.all(:conditions=>{:name=>["Research Datasets", "Teaching Datasets","Health Survey for England","General Household Survey"]})
    non_empty_survey_types = get_surveys
    survey_types.each do |survey_type|
      any_datasets = false
      survey_type.surveys.each do |survey|
        any_datasets = true unless survey.datasets.empty?
      end
      if any_datasets 
        non_empty_survey_types << survey_type
      end
    end
    @surveys_json = "{types:{\"Dataset\":{pluralLabel:\"Datasets\"}},"
    @surveys_json << "\"items\":["
    non_empty_survey_types.each do |survey_type|
    survey_type.surveys.each do |survey|
      unless !Authorization.is_authorized?("show", nil, survey, current_user)
        survey.datasets.each do |dataset|
          dataset.description ? dataset_description = dataset.description : dataset_description = 'N/A'
          survey.description ? survey_description = survey.description : survey_description = 'N/A'
          if dataset_description == ''
            dataset_description = 'N/A'
          end
          if survey_description == ''
            survey_description = 'N/A'
          end
          @surveys_json << "{\"label\":\"" + dataset.id.to_s + "\",\"name\":" + dataset.name.to_json + ",\"survey-type\":" + survey.survey_type.name.to_json + ",\"year\":" +  survey.year.to_json + ",\"type\" : \"Dataset\",\"dataset-description\" :" + dataset_description.to_json
          @surveys_json << ",\"Survey\":" + survey.title.to_json + ",\"survey-description\" :" + survey_description.to_json + ",\"url\":" + url_for(survey).to_json + "},"
        end
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

      links = Link.find(:all, :conditions => { :object_type => "Survey", :object_id => @survey.id, :predicate => "link",:user_id=>current_user.id })

      links.each do |link|
        case link.subject.class.name
        when "Csvarchive"
          source_archives.push(link.subject)
        when "Script"
          source_scripts.push(link.subject)
        end
      end

      @archives = source_archives
      @scripts = source_scripts
    when "all"
      source_archives = []
      source_scripts = []

      links = Link.find(:all, :conditions => { :object_type => "Survey", :object_id => params[:survey_id], :predicate => "link" })

      links.each do |link|
        case link.subject.class.name
        when "Csvarchive"
          source_archives.push(link.subject)
        when "Script"
          source_scripts.push(link.subject)
        end
      end

      @archives = source_archives
      @scripts = source_scripts
    end
    
    render :update do |page|
        page.replace_html "links",:partial=>"assets/link_view",:locals=>{:archives=>@archives, :scripts=>@scripts}
    end
  end

  def search_variables
    sunspot_search_variables
    #do_search_variables
  end

# list all the surveys that the current user can see.
  def index
    @surveys = get_surveys
    @surveys.sort!{|x,y| x.title <=> y.title}
    surveys_hash = {"total_entries" => @surveys.size, "results"=>@surveys.collect{ |s| {"id" => s.id, "title" => s.title, "description" => truncate_words(s.description, 50),  "type" => SurveyType.find(s.survey_type).name, "year" => s.year ? s.year : 'N/A', "source" => s.nesstar_id ? s.nesstar_uri : "methodbox"}}}
    @surveys_json = surveys_hash.to_json

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
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.survey_type.name.upcase }
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
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.survey_type.name.upcase }.reverse
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
    @variables = Array.new
    @survey_list = Array.new(params[:entry_ids])
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
      format.html # new.html.erb
    end
  end

  def create
    if (params[:survey_type_name])!= ""
      s_type = SurveyType.new
      s_type.name = params[:survey_type_name]
      #s_type.shortname = params[:survey_type_shortname]
      s_type.description = params[:survey_type_description]
      if params[:ukda_survey] == "yes"
        s_type.is_ukda = true
      else
        s_type.is_ukda = false
      end
      s_type.save
      params[:survey][:survey_type] = s_type
      #forum = Forum.new()
      #forum.name = s_type.shortname
      #forum.description = "Questions about " + s_type.name
      #forum.position = 4
      #forum.save
    else
      params[:survey][:survey_type] = SurveyType.find(params[:survey][:survey_type].to_i)
    end
    # prepare some extra metadata to store in Survey files instance
    params[:survey][:contributor_type] = "User"
    params[:survey][:contributor_id] = current_user.id
    @survey = Survey.new(params[:survey])
    #TODO: the flow seems to break the active record error display.
    respond_to do |format|
      if @survey.save
        expire_survey_cache
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
        flash[:notice] = 'Survey was successfully created.  You can now add datasets to it.'
        format.html { redirect_to survey_path(@survey) }
      else
        format.html {
          #TODO: this flash should really not be needed but the active record errors_for stuff is broke because of the page flow somehow.
          flash[:error] = 'There was an problem saving the survey.  Is the name unique?'
          set_parameters_for_sharing_form()
          redirect_to :action => "new"
        }
      end
    end
  end

  def show
    unless !Authorization.is_authorized?("show", nil, @survey, current_user)

    #@forum = Forum.all(:conditions=>["name=?", @survey.survey_type.shortname])[0]

    source_archives = []
    source_scripts = []
    # no survey link to publications yet, maybe in the future

    links = Link.find(:all, :conditions => { :object_type => "Survey", :object_id => @survey.id, :predicate => "link" })

    links.each do |link|
      case link.subject.class.name
      when "Csvarchive"
        source_archives.push(link.subject)
      when "Script"
        source_scripts.push(link.subject)
      end
    end

    @archives = source_archives
    @scripts = source_scripts
    
    find_all_categories_for_survey

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
      #expire the surveys index fragment for all users 
      begin
        User.all.each do |user|
          fragment = 'surveys_index_' + user.id.to_s
          if fragment_exist?(fragment)
            logger.info Time.now.to_s + " New survey so expiring cached fragment " + fragment
            expire_fragment(fragment)
          end
        end
        if fragment_exist?('surveys_index_anon')
          expire_fragment('surveys_index_anon')
        end
      rescue Exception => e
        logger.error Time.now.to_s + "Problem expiring cached fragment " + e.backtrace 
      end
        # update attributions
        Relationship.create_or_update_attributions(@survey, params[:attributions])

          flash[:notice] = 'Survey details were successfully updated.'
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
    found = Survey.find( :all, :order => "title" )
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

    # # obtain a policy to use
    if defined?(@survey) && @survey.asset
      if (policy = @survey.asset.policy)
        policy_type = "survey_policy"
      end
    end
    # 


    # set the parameters
    # ..from policy
    # policy = @survey.asset.policy
    unless policy
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
    if !params[:survey_search_query] or params[:survey_search_query].length == 0 or params[:survey_search_query] == "Enter search terms"
    respond_to do |format|
      flash[:error] = "Searching requires a term to be entered in the survey search box."
      format.html { redirect_to :back, :survey_search_query => search_query }
    end
    return false
  end
  end

 private 

  def sunspot_search_variables
    #figure out what datasets the current user is allowed to see
    authorized_datasets=[]
    #if there are no datasets selected then just search everything
    if params[:entry_ids] == nil || params[:entry_ids].empty?
      get_surveys.each do |survey|
        survey.datasets.each do |dataset|
          authorized_datasets.push(dataset.id) unless !Authorization.is_authorized?("show", nil, survey, current_user)
        end
      end
      params[:entry_ids] = authorized_datasets.collect{|dataset_id| dataset_id.to_s}
    else
      params[:entry_ids].each do |dataset_id| 
        authorized_datasets.push(dataset_id) unless !Authorization.is_authorized?("show", nil, Dataset.find(dataset_id).survey, current_user)
      end
    end
    result = Sunspot.search(Variable) do
      keywords(params[:survey_search_query]) {minimum_match 1}
      with(:dataset_id, authorized_datasets)
      paginate(:page => 1, :per_page => 1000)
    end
    @datasets_with_results = []
    result.results.each do |var|
      @datasets_with_results.push(var.dataset) if !@datasets_with_results.include?(var.dataset)
    end
    with_results = @datasets_with_results.collect{|dataset| dataset.id.to_s}
    @datasets_without_results = params[:entry_ids] - with_results
    #sunspot/solr paginates everything, we use client side pagination so just search for 1000 entries and send across - anything more would be a
    #bit crazy really
    variables_hash = {"total_entries"=>result.results.total_entries, "results" => result.results.sort{|x,y| x.name <=> y.name}.collect{|variable| {"id" => variable.id, "name"=> variable.name, "description"=>variable.value, "survey"=>variable.dataset.survey.title, "year"=>variable.dataset.survey.year, "category"=>variable.category, "popularity" => VariableList.all(:conditions=>"variable_id=" + variable.id.to_s).size}}}
    @survey_search_query = params[:survey_search_query]
    @variables_json = variables_hash.to_json
    #keep track of what  datasets have been searched
    @selected_datasets = authorized_datasets
    @sorted_variables = result.results
    if @sorted_variables.empty?
      flash[:notice] = "There are no variables which match the search \"" + @survey_search_query + "\". Please try again with different search terms."
    end
  end

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
            variables = find_variables(term, ids)
            variables.each do | variable |
              @term_results[term].push(variable)
              if !@sorted_variables.include?(variable)
                @sorted_variables.push(variable)
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

        end

        respond_to do |format|
          format.html { render :action =>:search_variables }
          format.xml { render :xml =>:search_variables }
        end
  end

  def rerouted_search
    if "search_variables".eql?(params[:id])
      params[:entry_ids] = params[:entry_ids].split(',')
      find_surveys
      check_search_parameters
      do_search_variables
     else
	return true
     end
   end

   #Note !SOLR_ENABLED is for testing purposes only and will not give as many results as SOLR_ENABLED
   def find_variables(term, dataset)
     if (SOLR_ENABLED)
        query = term + " AND dataset_id:" + dataset.to_s
        results = Variable.find_by_solr(query, :limit => 30)
        results.docs
      else
        results = Variable.find(:all, :conditions => ["name like ? or value like ? and dataset_id = ?", '%'+term+'%','%'+term+'%', dataset.to_s])
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
      categories = Variable.find_by_sql("select distinct(variables.category) from variables, datasets, surveys, survey_types where variables.dataset_id = datasets.id and datasets.survey_id = surveys.id and surveys.survey_type_id = #{survey_type_id}")
      @all_categories = categories.collect{|var| var.category}
      @all_categories.delete_if{|cat| cat==nil}
      @all_categories.sort!
      all_categories = @all_categories
      return all_categories
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
    
    def find_groups
      @groups = WorkGroup.all
    end

  def find_previous_searches
    search=[]
    if logged_in?
      search = UserSearch.all(:order => "created_at DESC", :limit => 5, :conditions => { :user_id => current_user.id})
    end
    @recent_searches = search
  end

end
