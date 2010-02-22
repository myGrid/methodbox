class ScriptsController < ApplicationController
  #FIXME: re-add REST for each of the core methods
  before_filter :login_required
  before_filter :find_scripts, :only => [ :index ]
  before_filter :find_archives, :find_surveys, :only => [ :new, :edit ]
  before_filter :find_cart
  before_filter :find_script_auth, :except => [ :index, :new, :create,:script_preview_ajax, :download_all_variables, :download_selected ]

  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]


  # GET /script
  def index
    @scripts.results=Authorization.authorize_collection("show",@scripts.results,current_user)
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml=>@scripts}
    end
  end

  def script_preview_ajax

    if params[:id] && params[:id]!="0"
      @script=Script.find(params[:id])
    end

    render :update do |page|
      if @script && Authorization.is_authorized?("show", nil, @script, current_user)
        page.replace_html "script_preview",:partial=>"assets/resource_preview",:locals=>{:resource=>@script}
      else
        page.replace_html "script_preview",:text=>"No Script is selected, or authorised to show."
      end
    end
  end

  # GET /scripts/1
  def show
    # store timestamp of the previous last usage
    @last_used_before_now = @script.last_used_at

    @archives = @script.csvarchives
    @surveys = @script.surveys

    # update timestamp in the current SOP record
    # (this will also trigger timestamp update in the corresponding Asset)
    @script.last_used_at = Time.now
    @script.save_without_timestamping

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /scripts/1;download
  def download
    # update timestamp in the current SOP record
    # (this will also trigger timestamp update in the corresponding Asset)
    @script.last_used_at = Time.now
    @script.save_without_timestamping

    send_data @script.content_blob.data, :filename => @script.original_filename, :content_type => @script.content_type, :disposition => 'attachment'
  end

  # GET /scripts/new
  #No auth check for loading new scripts, login is enough
  def new
    #    @archives = Csvarchive.find(:all)
    #    @archives=Authorization.authorize_collection("show",@archives,current_user)
    respond_to do |format|
      #if Authorization.is_member?(current_user.person_id, nil, nil)
      format.html # new.html.erb
      #else
      #flash[:error] = "You are not authorized to upload new Scripts. Only members of known projects, institutions or work groups are allowed to create new content."
      #format.html { redirect_to scripts_path }
      #end
    end
  end

  # GET /scripts/1/edit
  def edit

  end

  # POST /scripts
  def create
    if (params[:script][:data]).blank?
      respond_to do |format|
        flash.now[:error] = "Please select a file to upload."
        format.html {
          set_parameters_for_sharing_form()
          render :action => "new"
        }
      end
    elsif (params[:script][:data]).size == 0
      respond_to do |format|
        flash.now[:error] = "The file that you have selected is empty. Please check your selection and try again!"
        format.html {
          set_parameters_for_sharing_form()
          render :action => "new"
        }
      end
    else

      if params[:archive][:id] != ""
        all_archives_array = Array.new
        all_archives_array.push(Csvarchive.find(params[:archive][:id]))
        params[:script][:csvarchives] = all_archives_array
      end

      if params[:survey][:id] != ""
        all_surveys_array = Array.new
        all_surveys_array.push(Survey.find(params[:survey][:id]))
        params[:script][:surveys] = all_surveys_array
      end
      # create new Script and content blob - non-empty file was selected

      # prepare some extra metadata to store in Script instance
      params[:script][:contributor_type] = "User"
      params[:script][:contributor_id] = current_user.id
      params[:script][:method_type] = params[:method_type]

      # store properties and contents of the file temporarily and remove the latter from params[],
      # so that when saving main object params[] wouldn't contain the binary data anymore
      params[:script][:content_type] = (params[:script][:data]).content_type
      params[:script][:original_filename] = (params[:script][:data]).original_filename
      data = params[:script][:data].read
      params[:script].delete('data')

      # store source and quality of the new Script (this will be kept in the corresponding asset object eventually)
      # TODO set these values to something more meaningful, if required for SOPs
      params[:script][:source_type] = "upload"
      params[:script][:source_id] = nil
      params[:script][:quality] = nil


      @script = Script.new(params[:script])
      @script.content_blob = ContentBlob.new(:data => data)

      respond_to do |format|
        if @script.save
          # the Script was saved successfully, now need to apply policy / permissions settings to it
          policy_err_msg = Policy.create_or_update_policy(@script, current_user, params)

          # update attributions
          Relationship.create_or_update_attributions(@script, params[:attributions])

          if policy_err_msg.blank?
            #            flash[:notice] = 'Script was successfully uploaded and saved.'
            format.html { redirect_to script_path(@script) }
          else
            flash[:notice] = "Script was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
            format.html { redirect_to :controller => 'scripts', :id => @script, :action => "edit" }
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


  # PUT /scripts/1
  def update
    # remove protected columns (including a "link" to content blob - actual data cannot be updated!)
    if params[:script]
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at,:method_type].each do |column_name|
        params[:script].delete(column_name)
      end

      # update 'last_used_at' timestamp on the Script
      params[:script][:last_used_at] = Time.now

      # update 'contributor' of the Script to current user (this under no circumstances should update
      # 'contributor' of the corresponding Asset: 'contributor' of the Asset is the "owner" of this
      # Script, e.g. the original uploader who has unique rights to manage this Script; 'contributor' of the
      # Script on the other hand is merely the last user to edit it)
      params[:script][:contributor_type] = current_user.class.name
      params[:script][:contributor_id] = current_user.id
      params[:script][:method_type] = params[:method_type]
    end

    respond_to do |format|
      if @script.update_attributes(params[:script])
        # the Script was updated successfully, now need to apply updated policy / permissions settings to it
        policy_err_msg = Policy.create_or_update_policy(@script, current_user, params)

        # update attributions
        Relationship.create_or_update_attributions(@script, params[:attributions])

        if policy_err_msg.blank?
          flash[:notice] = 'Script metadata was successfully updated.'
          format.html { redirect_to script_path(@script) }
        else
          flash[:notice] = "Script metadata was successfully updated. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
          format.html { redirect_to :controller => 'scripts', :id => @script, :action => "edit" }
        end
      else
        format.html {
          set_parameters_for_sharing_form()
          render :action => "edit"
        }
      end
    end
  end

  # DELETE /scripts/1
  def destroy
    @script.destroy

    respond_to do |format|
      format.html { redirect_to(scripts_url) }
    end
  end


  protected

  def find_scripts
    found = Script.find(:all,
      :order => "title",:page=>{:size=>default_items_per_page,:current=>params[:page]})
    #    found = Script.find(:all,
    #      :order => "title")

    # this is only to make sure that actual binary data isn't sent if download is not
    # allowed - this is to increase security & speed of page rendering;
    # further authorization will be done for each item when collection is rendered
    found.each do |script|
      script.content_blob.data = nil unless Authorization.is_authorized?("download", nil, script, current_user)
    end

    @scripts = found
  end

  def find_archives
    @archives = Csvarchive.find(:all)
    @archives=Authorization.authorize_collection("show",@archives,current_user)
  end

  def find_surveys
    @surveys = Survey.find(:all)
    #    @surveys=Authorization.authorize_collection("show",@surveys,current_user)
  end


  def find_script_auth
    begin
      script = Script.find(params[:id])

      if Authorization.is_authorized?(action_name, nil, script, current_user)
        @script = script
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to scripts_path }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the Script or you are not authorized to view it"
        format.html { redirect_to scripts_path }
      end
      return false
    end
  end


  def set_parameters_for_sharing_form
    policy = nil
    policy_type = ""

    # obtain a policy to use
    if defined?(@script) && @script.asset
      if (policy == @script.asset.policy)
        # Script exists and has a policy associated with it - normal case
        policy_type = "asset"
      elsif @script.asset.project && (policy == @script.asset.project.default_policy)
        # Script exists, but policy not attached - try to use project default policy, if exists
        policy_type = "project"
      end
    end

    unless policy
      # several scenarios could lead to this point:
      # 1) this is a "new" action - no Script exists yet; use default policy:
      #    - if current user is associated with only one project - use that project's default policy;
      #    - if current user is associated with many projects - use system default one;
      # 2) this is "edit" action - SOP exists, but policy wasn't attached to it;
      #    (also, Script wasn't attached to a project or that project didn't have a default policy) --
      #    hence, try to obtain a default policy for the contributor (i.e. owner of the Script) OR system default
      #      projects = current_user.person.projects
      #      if projects.length == 1 && (proj_default = projects[0].default_policy)
      #        policy = proj_default
      #        policy_type = "project"
      #      else
      policy = Policy.default(current_user)
      policy_type = "project"
      #      end
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
    @resource_type = "Script"
    @favourite_groups = current_user.favourite_groups

    @all_people_as_json = Person.get_all_as_json

  end

end
