class ScriptsController < ApplicationController
  #FIXME: re-add REST for each of the core methods
  before_filter :login_required, :except => [ :download, :index, :show, :help, :help2]
  before_filter :find_scripts_by_page, :only => [ :index ]
  before_filter :set_paramemeters_for_new_edit, :only => [ :new, :edit]
  before_filter :find_script_auth, :except => [ :thumbs_down, :thumbs_up, :help, :help2, :index, :new, :create,:script_preview_ajax, :download_all_variables, :download_selected, :show_links,:add_comment ]
  before_filter :find_comments, :only=>[ :show ]
  before_filter :recommended_by_current_user, :only=>[ :show ]
  after_filter :update_last_user_activity
  
  # you don't like it any more
  def thumbs_down
    @script = Script.find(params[:id])
    if @script.contributor_id != current_user
      Recommendation.all(:conditions => {:user_id=>current_user.id, :recommendable_id=>@script.id, :recommendable_type=>"Script"})[0].destroy
      render :update do |page|
          page.replace_html 'recommended', :partial=>"recommendations/thumbs_up", :locals=>{:item=>@script}
          page.replace_html 'award', :partial => "recommendations/awards", :locals => { :count => @script.recommendations.size }
      end
    end
  end
  
  # show that you like a script
  def thumbs_up
    @script = Script.find(params[:id])
    if @script.contributor_id != current_user
      recommendation = Recommendation.new(:user_id=>current_user.id, :recommendable_id=>@script.id, :recommendable_type=>"Script")
      recommendation.save
      render :update do |page|
          page.replace_html 'recommended', :partial=>"recommendations/thumbs_down", :locals=>{:item=>@script}
          page.replace_html 'award', :partial => "recommendations/awards", :locals => { :count => @script.recommendations.size }
      end
    end
  end
  #add a user owned comment to a script and add it to the view
  def add_comment
    @script = Script.find(params[:resource_id])
    comment = Comment.new(:words=>params[:words], :user_id=>current_user.id, :commentable_id=>@script.id, :commentable_type=>"Script")
    comment.save
    render :partial=>"comments/comment", :locals=>{:comment=>comment}
  end
  
  def save_comment

  end
  
  #only show 'my' links or 'all' links
  def show_links
    puts "doing stuff"
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
      links = Link.find(:all, :conditions => { :subject_type => "Script", :subject_id => params[:script_id], :predicate => "link", :user_id => current_user.id })
      links.each do |link|
        case link.object.class.name
        when "Csvarchive"
          source_archives.push(link.object)
        when "Script"
          source_scripts.push(link.object)
        when "Survey"
          source_surveys.push(link.object)
        when "Publication"
          @publications.push(link.object)
        end
        
        target_links = Link.find(:all, :conditions => { :object_type => "Script", :object_id => params[:script_id], :predicate => "link", :user_id => current_user.id })
        target_links.each do |link|
          case link.subject.class.name
          when "Csvarchive"
            target_archives.push(link.subject)
          when "Script"
            target_scripts.push(link.subject)
          when "Survey"
            target_surveys.push(link.subject)
          end
        end
      end
      @archives = source_archives | target_archives
      @scripts = source_scripts | target_scripts
      @surveys = source_surveys | target_surveys
    when "all"
      links = Link.find(:all, :conditions => { :subject_type => "Script", :subject_id => params[:script_id], :predicate => "link"})
      links.each do |link|
        case link.object.class.name
        when "Csvarchive"
          source_archives.push(link.object)
        when "Script"
          source_scripts.push(link.object)
        when "Survey"
          source_surveys.push(link.object)
        when "Publication"
          @publications.push(link.object)
        end
        
        target_links = Link.find(:all, :conditions => { :object_type => "Script", :object_id => params[:script_id], :predicate => "link"})
        target_links.each do |link|
          case link.subject.class.name
          when "Csvarchive"
            target_archives.push(link.subject)
          when "Script"
            target_scripts.push(link.subject)
          when "Survey"
            target_surveys.push(link.subject)
          end
        end
      end
      @archives = source_archives | target_archives
      @scripts = source_scripts | target_scripts
      @surveys = source_surveys | target_surveys
    end
    
    render :update do |page|
        page.replace_html "links",:partial=>"assets/link_view",:locals=>{:archives=>@archives, :scripts=>@scripts,:surveys=>@surveys,:publications=>@publications}
    end
    
  end
  # GET /script
  def index
    # found = Script.find(:all,
    #   :order => "title",:page=>{:size=>default_items_per_page,:current=>params[:page]})
    # #    found = Script.find(:all,
    # #      :order => "title")
    #
    # # this is only to make sure that actual binary data isn't sent if download is not
    # # allowed - this is to increase security & speed of page rendering;
    # # further authorization will be done for each item when collection is rendered
    # found.each do |script|
    #   script.content_blob.data = nil unless Authorization.is_authorized?("download", nil, script, current_user)
    # end
    # puts "before authorize" + found.results.size.to_s
    # scripts = found
    # scripts.results=Authorization.authorize_collection("show",scripts.results,current_user)
    #  puts "after authorize" + scripts.results.size.to_s
    # @scripts = scripts
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
  #find all the links with other records for this script, include links where it is either the 'object'
  #or the 'subject'
  def show
    # store timestamp of the previous last usage
    @last_used_before_now = @script.last_used_at
    source_archives = []
    source_surveys = []
    source_scripts = []
    target_archives = []
    target_surveys = []
    target_scripts = []
    #publications link to something, not from
    @publications = []
    

    links = Link.find(:all, :conditions => { :subject_type => "Script", :subject_id => @script.id, :predicate => "link" })

    links.each do |link|
      case link.object.class.name
      when "Csvarchive"
        source_archives.push(link.object)
      when "Script"
        source_scripts.push(link.object)
      when "Survey"
        source_surveys.push(link.object)
      when "Publication"
        @publications.push(link.object)
      end
    end

    target_links = Link.find(:all, :conditions => { :object_type => "Script", :object_id => @script.id, :predicate => "link" })

    target_links.each do |link|
      case link.subject.class.name
      when "Csvarchive"
        target_archives.push(link.subject)
      when "Script"
        target_scripts.push(link.subject)
      when "Survey"
        target_surveys.push(link.subject)
      end
    end

    @archives = source_archives | target_archives
    @scripts = source_scripts | target_scripts
    @surveys = source_surveys | target_surveys

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
      record_download @script 
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

  #When editing display all the links which have been made from this Script, only include those for which it is the 'subject'
  # GET /scripts/1/edit
  def edit
    if @script.asset.policy.get_settings["sharing_scope"] == Policy::CUSTOM_PERMISSIONS_ONLY
      @sharing_mode = Policy::CUSTOM_PERMISSIONS_ONLY
      @script.asset.policy.permissions.each do |permission|
        if permission.contributor_type == "WorkGroup"
          puts "Shared with group " + permission.contributor_id.to_s
          @selected_groups.push(permission.contributor_id)
        end
      end
    end

    #find links where this Script is the source
    links = Link.find(:all, :conditions => { :subject_type => "Script", :subject_id => @script.id, :predicate => "link" })

    links.each do |link|
      case link.object.class.name
      when "Csvarchive"
        @selected_archives.push(link.object.id)
      when "Script"
        @selected_scripts.push(link.object.id)
      when "Survey"
        @selected_surveys.push(link.object.id)
      when "Publication"
        @selected_publications.push(link.object.id)
      end
    end

  end

  # POST /scripts
  def create
    if !params[:script]
      create_failed("Please use form to create a script.")
    elsif (params[:script][:data]).blank?
      create_failed("Please select a file to upload.")
    elsif (params[:script][:data]).size == 0
      create_failed("The file that you have selected is empty. Please check your selection and try again!")
    else

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
          puts "saved script"
          #save all the links.
          #at the moment all the links have predicates of 'link' but this could change in the future to a user defined one
          #this would mean that each Linkage could have many different reasons
          if params[:scripts] != nil
            # all_scripts_array = Array.new
            params[:scripts].each do |script_id|
            link = Link.new
            link.subject = @script
            link.object = Script.find(script_id)
            link.predicate = "link"
            link.user = current_user
            link.save
            end
          end
          if params[:surveys] != nil
              params[:surveys].each do |survey_id|
                 link = Link.new
                 link.subject = @script
                 link.object = Survey.find(survey_id)
                 link.predicate = "link"
                 link.user = current_user
                 link.save
              end
          end
          if params[:data_extracts] != nil
              params[:data_extracts].each do |extract_id|
                 link = Link.new
                 link.subject = @script
                 link.object = Csvarchive.find(extract_id)
                 link.predicate = "link"
                 link.user = current_user
                 link.save
              end
          end
          if params[:publications] != nil
            # all_scripts_array = Array.new
            params[:publications].each do |publication_id|
            link = Link.new
            link.subject = @script
            link.object = Publication.find(publication_id)
            link.predicate = "link"
            link.user = current_user
            link.save
            end
          end

           if params[:groups] != nil && params[:sharing][:sharing_scope] == Policy::CUSTOM_PERMISSIONS_ONLY.to_s
             puts "custom sharing here"
             values = "{"
                params[:groups].each do |workgroup_id|
                   values = values + workgroup_id.to_s + ": {\"access_type\": 2}" + ","
                end
                values = values.chop
                values << "}}"
                values.insert(0,"{\"WorkGroup\":")
                params[:sharing][:permissions][:values] = values
                params[:sharing][:permissions][:contributor_types] = "[\"WorkGroup\"]"
                logger.info "custom permissions: " + values
                puts params[:sharing][:permissions][:values]
                puts params[:sharing][:permissions][:contributor_types]
            end

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
            set_paramemeters_for_new_edit()
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
      # params[:script].script_lists.each do |list|
      #   list.delete
      # end
      # params[:script].survey_to_script_lists.each do |list|
      #   list.delete
      # end
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

      #remove all the existing links where this Script is the source
      links = Link.find(:all,
                                   :conditions => { :subject_type => "Script",
                                                    :subject_id => @script.id,
                                                    :predicate => "link" })

      links.each do |link|
        link.delete
      end
      #add the links again
      if params[:scripts] != nil
        # all_scripts_array = Array.new
        params[:scripts].each do |script_id|
        link = Link.new
        link.subject = @script
        link.object = Script.find(script_id)
        link.predicate = "link"
        link.user = current_user
        link.save
        end
      end
      if params[:surveys] != nil
          params[:surveys].each do |survey_id|
             link = Link.new
             link.subject = @script
             link.object = Survey.find(survey_id)
             link.predicate = "link"
             link.user = current_user
             link.save
          end
      end
      if params[:data_extracts] != nil
          params[:data_extracts].each do |extract_id|
             link = Link.new
             link.subject = @script
             link.object = Csvarchive.find(extract_id)
             link.predicate = "link"
             link.user = current_user
             link.save
          end
      end
      if params[:publications] != nil
        params[:publications].each do |publication_id|
        link = Link.new
        link.subject = @script
        link.object = Publication.find(publication_id)
        link.predicate = "link"
        link.user = current_user
        link.save
        end
      end

      if params[:groups] != nil && params[:sharing][:sharing_scope] == Policy::CUSTOM_PERMISSIONS_ONLY.to_s
        puts "custom sharing here"
        values = "{"
           params[:groups].each do |workgroup_id|
              values = values + workgroup_id.to_s + ": {\"access_type\": 2}" + ","
           end
           values = values.chop
           values << "}}"
           values.insert(0,"{\"WorkGroup\":")
           params[:sharing][:permissions][:values] = values
           params[:sharing][:permissions][:contributor_types] = "[\"WorkGroup\"]"
           logger.info "custom permissions: " + values
           puts params[:sharing][:permissions][:values]
           puts params[:sharing][:permissions][:contributor_types]
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
          set_paramemeters_for_new_edit()
          render :action => "edit"
        }
      end
    end
  end

  # DELETE /scripts/1
  def destroy
    #destroy any links to or from this script
    links = Link.find(:all, :conditions => { :object_type => "Script", :object_id => @script.id, :predicate => "link" })
    links.each do |link|
      link.destroy
    end
    links = Link.find(:all, :conditions => { :subject_type => "Script", :subject_id => @script.id, :predicate => "link" })
    links.each do |link|
      link.destroy
    end
    @script.destroy

    respond_to do |format|
      format.html { redirect_to(scripts_url) }
    end
  end


  protected

#find all scripts, authorize them for view by the user, paginate them 
  def find_scripts_by_page
    scripts = Script.find(:all,:order => "created_at DESC")
    authorized_scripts = Authorization.authorize_collection("view", scripts, current_user, keep_nil_records=false)
    @scripts = authorized_scripts.paginate(:page=>params[:page] ? params[:page] : 1, :per_page=>default_items_per_page)
  end

  def find_scripts
    @selected_scripts=[] unless @selected_scripts

    found = Script.find(:all)
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

  def find_groups
    @selected_groups = [] unless @selected_groups
    @groups = WorkGroup.find(:all)
  end

  def find_archives
    @selected_archives=[] unless @selected_archives

    @archives = Csvarchive.all
    @archives=Authorization.authorize_collection("show",@archives,current_user)
  end

  def find_surveys
    @selected_surveys=[] unless @selected_surveys

    @surveys = Survey.find(:all)
    #    @surveys=Authorization.authorize_collection("show",@surveys,current_user)
  end
  
  def find_publications
    @selected_publications = [] unless @selected_publications
    @publications = Publication.all
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

  def set_paramemeters_for_new_edit
    find_scripts
    find_archives
    find_surveys
    find_groups
    find_publications

    set_parameters_for_sharing_form
  end

  def create_failed(message)
    respond_to do |format|
      flash.now[:error] = message
      format.html {
        set_paramemeters_for_new_edit()
        render :action => "new"
      }
    end
  end
  
  def find_comments
    @script =Script.find(params[:id])
    @comments = @script.comments
  end
  
  # does the current user like this script
  def recommended_by_current_user
    if current_user
      script =Script.find(params[:id])
      s_rec = script.recommendations
      u_rec = current_user.recommendations
      all_rec =  s_rec & u_rec
      if !all_rec.empty?
        @recommended =  true
      else
        @recommended =  false
      end
    else
      @recommended =  false
    end
  end

end
