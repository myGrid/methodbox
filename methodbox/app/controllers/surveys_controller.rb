class SurveysController < ApplicationController

  before_filter :login_required

  before_filter :find_cart

  before_filter :find_surveys, :only => [ :index, :search_variables ]
  #before_filter :find_survey_auth, :except => [ :index, :new, :create,:survey_preview_ajax ]

  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]

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

      @survey_search_query = params[:survey_search_query]
      @selected_surveys = Array.new(params[:entry_ids])
      #    logger.info("length " + @survey_list.size)
      #    @search_query||=""

      downcase_query = @survey_search_query.downcase
      logger.info("Search for: " + downcase_query)

      @results = Variable.find_by_solr(downcase_query,:limit => 1000)
      @variables = @results.docs
      @sorted_variables = Array.new
      @variables.each do |item|
        @selected_surveys.each do |ids|
          if Dataset.find(item.dataset_id).id.to_s == ids
            logger.info("Found " + item.name + ", from Survey " + item.dataset_id.to_s)
            puts "Found " + item.name + ", from Survey " + item.dataset_id.to_s
            @sorted_variables.push(item)
            break
          end
        end
      

      end

      case params['sort']
      when "variable"
        @sorted_variables = @unsorted_vars.sort_by { |m| m.name.upcase }
      when "description"   then "description"
        @sorted_variables = @unsorted_vars.sort_by { |m| m.value.upcase }
      when "category"   then "category"
        @sorted_variables = @unsorted_vars.sort_by { |m| m.category.upcase }
      when "survey" then "survey"
        @sorted_variables = @unsorted_vars.sort_by { |m| Survey.find(m.survey_id).surveytype.upcase }
      when "year" then "year"
        @sorted_variables = @unsorted_vars.sort_by { |m| Survey.find(m.survey_id).year }
      when "variable_reverse"  then "variable DESC"
        @sorted_variables = @unsorted_vars.sort_by { |m| m.name.upcase }.reverse
      when "category_reverse"   then "category DESC"
        @sorted_variables = @unsorted_vars.sort_by { |m| m.category.upcase }.reverse
      when "description_reverse"   then "description DESC"
        @sorted_variables = @unsorted_vars.sort_by { |m| m.value.upcase }.reverse
      when "survey_reverse" then "survey DESC"
        @sorted_variables = @unsorted_vars.sort_by { |m| Survey.find(m.survey_id).surveytype.upcase }.reverse
      when "year_reverse" then "year DESC"
        @sorted_variables = @unsorted_vars.sort_by { |m| Survey.find(m.survey_id).year }.reverse
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
      respond_to do |format|
        format.html {
          flash[:error] = "Searching requires a term to be entered in the survey search box and at least one survey selected."
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
    end
    render :update, :status=>:created do |page|
      page.replace_html "table_header", :partial=>"surveys/table_header"
      page.replace_html "table_container", :partial=>"surveys/table"
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
      page.replace_html @div, :partial=>"surveys/variables_table_replaced_row",:locals=>{:curr_cycle=>@curr_cycle,:item => @item}
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

end
