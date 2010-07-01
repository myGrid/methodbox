class SurveysController < ApplicationController

  before_filter :login_required, :except => [ :help, :index, :search_variables, :sort_variables, :show]

  before_filter :find_previous_searches, :only => [ :index]

  before_filter :find_surveys, :only => [ :index, :search_variables ]
  
  before_filter :find_previous_searches, :only => [ :index ]
   
  #before_filter :find_survey_auth, :except => [ :index, :new, :create,:survey_preview_ajax, :help ]

  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]

  before_filter :check_search_parameters, :only => [:search_variables]

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

  def index
    #@surveys=Authorization.authorize_collection("show",@surveys,current_user)

    @survey_hash = Hash.new
    @surveys.each do |survey|
      if (!@survey_hash.has_key?(survey.surveytype))
        @survey_hash[survey.surveytype] = Array.new
      end
      @survey_hash[survey.surveytype].push(survey)
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
      format.json {render :json => results.to_jqgrid_json([:name,:value,"survey.title","survey.surveytype"], params[:page], params[:rows], results.size)}
    end
  end

  #  def hide_variables
  #    puts "hiding variables"
  #    variable_list = params[:sorted_variables]
  #    puts "original list: " + params[:sorted_variables].to_json
  #    puts "var list: " + variable_list.to_json
  #    @all_variables = params[:all_variables]
  #    current_datasets = params[:current_datasets]
  #    @all_datasets = params[:all_datasets]
  #    temp_variable_list = Array.new
  #    dataset_to_remove = params[:dataset_id]
  #    current_datasets.delete(dataset_to_remove)
  #    puts "removing dataset " + dataset_to_remove
  #    @sorted_variables = Array.new
  #    variable_list.each do |var|
  #      variable = Variable.find(var)
  #      puts "var: " + variable.id.to_s + " dataset: " + variable.dataset_id.to_s
  #      if !(variable.dataset_id.to_s == dataset_to_remove.to_s)
  #        puts "adding" + var.to_s
  #        @sorted_variables.push(variable)
  #      end
  #    end
  #    puts @sorted_variables.to_json
  ##    temp_variable_list.each do |id|
  ##      puts "adding " + id.to_s
  ##      @sorted_variables.push(Variable.find(id))
  ##    end
  ##    puts "sorted var list: " + @sorted_variables.to_json
  #    @all_variables = variable_list
  #    @current_datasets = current_datasets
  #
  #    render :update, :status=>:created do |page|
  #      page.replace_html "dataset_checkbox_list", :partial => "surveys/dataset_checkbox_list",:locals=>{:current_datasets => @current_datasets, :all_variables => @all_variables, :sorted_variables => @sorted_variables, :all_datasets => @all_datasets}
  #      page.replace_html "table_header", :partial=>"surveys/table_header"
  #      page.replace_html "table_container", :partial=>"surveys/table", :locals => {:sorted_variables => @sorted_variables}
  #    end
  #  end

  #  def show_variables
  #    puts "showing variables"
  #    render :update, :status=>:created do |page|
  #      #      page.replace_html @div, :partial=>"surveys/variables_table_expanded_row",:locals=>{:curr_cycle=>@curr_cycle, :item => @item}
  #    end
  #  end

  def search_variables

    begin
      #    items_per_page = 10
      #  if (params[:search_query]== "" || params[:entry_ids]== nil)
      #respond_to do |format|
      #      flash.now[:notice] = "Searching requires a term to be entered in the survey search box and at least one survey selected."
      #      format.html {
      #        render :action => :index
      #      }
      #    end
      #
      #  else
      #    case params['sort']
      #    when nil
      # page = params[:page]
      #      number_per_page = params[:number_per_page]
      @survey_search_query = params[:survey_search_query]
      @selected_surveys = Array.new(params[:entry_ids])
      @current_datasets = Array.new(params[:entry_ids])
      @all_datasets = Array.new(params[:entry_ids])
      #    logger.info("length " + @survey_list.size)
      #    @search_query||=""
      # user_search = UserSearch.new
      #      user_search.person = Person.find(current_user.person_id)
      #      user_search.terms = @survey_search_query
      #      user_search.dataset_ids = @all_datasets
      #      user_search.save
      search_terms = @survey_search_query.split(' ')
      search_terms.each do |search_term|
        t = SearchTerm.find(:all, :conditions=>["term=?",search_term])
        if t.size == 0
          t = SearchTerm.new
          t.term = search_term
          t.save
        end
      end

      if search_terms.length > 1
        downcase_query = @survey_search_query.downcase
        search_terms.unshift(downcase_query)
      end

      logger.info("searching for " + search_terms.to_s)
      temp_variables = Array.new
      search_terms.each do |term|
        variables = find_variables(term)
        variables.each do |item|
          @selected_surveys.each do |ids|
            #if Dataset.find(item.dataset_id).id.to_s == ids
            if item.dataset_id.to_s == ids
              logger.info("Found " + item.name + ", from Survey " + item.dataset_id.to_s)
              #uts "Found " + item.name + ", from Survey " + item.dataset_id.to_s
              contains = false
              temp_variables.each do |temp_item|
                if temp_item.id == item.id
                  contains = true
                  break
                end
              end
              if contains == false
                temp_variables.push(item)
              end
              break
            end
          end

        end
      end
      
      #remove any variables which do not match the current dataset version number,ie those from a previous update
      temp_variables.delete_if {|x| Dataset.find(x.dataset_id).current_version != x.current_version}
      
      #      puts temp_variables.to_json
      @sorted_variables = temp_variables
      #      @all_variables = @sorted_variables

      case params['add_results']
      when "yes"
        new_variable_list = Array.new
        current_variables = params[:variable_list]
        #        temp_variables.each do |temp_item|
        #
        #          contains = false
        current_variables.each do |var|
          temp_variables.delete_if {|x| x.id.to_s == var.to_s}
          #            puts var.to_s + " " + temp_item.id.to_s
          #            if var.to_s == temp_item.id.to_s
          #              contains = true
          #              puts contains.to_s
          #              break
          #            end
          #            if contains == false
          #              #              v = Variable.find(temp_item)
          #              current_variables.push(temp_item.id)
          #            end
        end
        #        end
        #        puts "curr var" + current_variables.to_json
        #        @sorted_variables.each do |var|
        #          new_variables.push(var)
        #        end
        current_variables.each do |id|
          #          puts "pushing " + id.to_s
          v = Variable.find(id)
          new_variable_list.push(v)
        end
        new_variable_list.concat(temp_variables)
        @sorted_variables = new_variable_list
      when "no"
        #don't have to do anything
      end

      #    when "variable"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| m.name.upcase }
      #    when "dataset"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).name.upcase }
      #    when "description"   then "description"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| m.value.upcase }
      #    when "category"   then "category"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| m.category.upcase }
      #    when "survey" then "survey"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.surveytype.upcase }
      #    when "year" then "year"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.year }
      #    when "variable_reverse"  then "variable DESC"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| m.name.upcase }.reverse
      #    when "category_reverse"   then "category DESC"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| m.category.upcase }.reverse
      #    when "description_reverse"   then "description DESC"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| m.value.upcase }.reverse
      #    when "dataset_reverse"   then "dataset DESC"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).name.upcase }.reverse
      #    when "survey_reverse" then "survey DESC"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.surveytype.upcase }.reverse
      #    when "year_reverse" then "year DESC"
      #      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.year }.reverse
      #    end
      if logged_in?
        user_search = UserSearch.new
        user_search.user = current_user
        user_search.terms = @survey_search_query
        user_search.dataset_ids = @all_datasets
        var_as_ints = Array.new
        @sorted_variables.each do |temp_var|
          var_as_ints.push(temp_var.id)
        end
        user_search.variable_ids = var_as_ints
        user_search.save
      end
      respond_to do |format|
        logger.info("rendering survey search")
        format.html
        format.xml
      end
      #    render :update, :status=>:created do |page|
      #      page.replace_html "table", :partial=>"surveys/variables_table"
      #    end
      #   respond_to do |format|
      #     format.html
      #   end
      #end
    rescue
      puts "Searching failed: " + $!
      respond_to do |format|
        format.html {
          flash[:error] = "Searching failed. Probably due to bad paramteres. Use the survey search box."
          redirect_to :action => "index"
        }
      end
      #      render :update do |page|
      #      render :action => index
      #         page.reload_flash_error
      #page.replace_html "survey_flash_error" , :partial => "layouts/flash_error",:locals=>{:error_message=>@error_message}
      #page.show "error_flash"
      #    page.visual_effect :highlight, 'error_flash'
      #flash.discard
      #      end
      #    redirect_to :action => index
      #    flash[:error] = "Searching requires a term to be entered in the survey search box and at least one survey selected."
      #        render :action => :index
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
      @sorted_variables = @unsorted_vars.sort_by { |m| m.value.upcase }
    when "category"   then "category"
      @sorted_variables = @unsorted_vars.sort_by { |m| m.category.upcase }
    when "survey" then "survey"
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.surveytype.upcase }
    when "year" then "year"
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.year }
    when "frequency" then "frequency"
      @sorted_variables = @unsorted_vars.sort_by { |m| VariableList.all(:conditions=>"variable_id=" + m.id.to_s).size}
    when "variable_reverse"  then "variable DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| m.name.upcase }.reverse
    when "category_reverse"   then "category DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| m.category.upcase }.reverse
    when "description_reverse"   then "description DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| m.value.upcase }.reverse
    when "dataset_reverse"   then "dataset DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).name.upcase }.reverse
    when "survey_reverse" then "survey DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.surveytype.upcase }.reverse
    when "year_reverse" then "year DESC"
      @sorted_variables = @unsorted_vars.sort_by { |m| Dataset.find(m.dataset_id).survey.year }.reverse
    when "frequency_reverse" then "frequency DESC"
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
    if (params[:survey][:data]).blank?
      respond_to do |format|
        flash.now[:error] = "Please select a file to upload."
        format.html {
          set_parameters_for_sharing_form()
          render :action => "new"
        }
      end
    elsif (params[:survey][:data]).size == 0
      respond_to do |format|
        flash.now[:error] = "The file that you have selected is empty. Please check your selection and try again!"
        format.html {
          set_parameters_for_sharing_form()
          render :action => "new"
        }
      end
    else
      # create new Survey file and content blob - non-empty file was selected

      # prepare some extra metadata to store in Survey files instance
      params[:survey][:contributor_type] = "User"
      params[:survey][:contributor_id] = current_user.id

      # store properties and contents of the file temporarily and remove the latter from params[],
      # so that when saving main object params[] wouldn't contain the binary data anymore
      params[:survey][:content_type] = (params[:survey][:data]).content_type
      params[:survey][:original_filename] = (params[:survey][:data]).original_filename
      data = params[:survey][:data].read
      name = (params[:survey][:data]).original_filename
      params[:survey].delete('data')

      directory = "public/data"
      # create the file path
      path = File.join(directory, name)
      # write the file
      File.open(path, "wb") do |f|
        f.write(data)
      end


      # store source and quality of the new Survey file (this will be kept in the corresponding asset object eventually)
      # TODO set these values to something more meaningful, if required for Survey files
      params[:survey][:source_type] = "upload"
      params[:survey][:source_id] = nil
      params[:survey][:quality] = nil


      @survey = Survey.new(params[:survey])
      @survey.
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
    end
  end

  def show
    # store timestamp of the previous last usage
    #    @last_used_before_now = @survey.last_used_at

    # update timestamp in the current Survey file record
    # (this will also trigger timestamp update in the corresponding Asset)
    #    @survey.last_used_at = Time.now
    #    @survey.save_without_timestamping

    @survey = Survey.find(params[:id])
    @forum = Forum.all(:conditions=>["name=?", @survey.title])[0]
    
    source_archives = []
    source_scripts = []

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
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml {render :xml=>@survey}
    end
  end

  def edit

  end

  def update
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
    if !params[:survey_search_query] or params[:survey_search_query].length == 0 or params[:survey_search_query] == "Enter search terms"
      error = "Searching requires a term to be entered in the survey search box."
    elsif !params[:entry_ids] or params[:entry_ids].size == 0
      error = "Searching requires at least one survey selected."
    else
      return true
    end
    respond_to do |format|
      flash[:error] = error
      format.html { redirect_to surveys_path }
    end
    return false
  end

 private

    #Note !SOLR_ENABLED is for testing purposes only and will not give as many results as SOLR_ENABLED
    def find_variables(term)
      if (SOLR_ENABLED)
        results = Variable.find_by_solr(term,:limit => 1000)
        results.docs
      else
        results = Variable.find(:all, :conditions => ["name like ? or value like ?", '%'+term+'%','%'+term+'%'])
      end
    end

end
