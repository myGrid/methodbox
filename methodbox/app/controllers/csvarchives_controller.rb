require 'uuidtools'
require 'zip/zip'
require 'zip/zipfilesystem'
require 'tempfile'
require 'cgi'

class CsvarchivesController < ApplicationController
  
  include DataExtractJob
  
  before_filter :login_required, :except => [ :index, :show, :download, :help, :help2, :download_stats_script]
  before_filter :find_archives_by_page, :only => [ :index]
  before_filter :find_scripts, :find_surveys, :find_archives, :find_groups, :find_publications, :only => [ :new, :edit ]
  before_filter :find_archive, :only => [ :edit, :update, :show, :download, :download_stats_script ]
  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]
  before_filter :recommended_by_current_user, :only=>[ :show ]
  after_filter :update_last_user_activity
  before_filter :find_comments, :only => [ :show ]
  before_filter :find_notes, :only => [ :show ]
  
  #a users notes about a resource
  def add_note
    @extract = Csvarchive.find(params[:resource_id])
    note = Note.new(:words=>params[:words], :user_id=>current_user.id, :notable_id=>@extract.id, :notable_type=>"Csvarchive")
    note.save
    render :partial=>"notes/note", :locals=>{:note=>note}
  end

  def download_stats_script
    # firstly check if the current user has the authorization to see the extract
    if Authorization.is_authorized?("view", nil, @archive, current_user)
      # then check the individual surveys to see if any preclude them downloading it
      if @archive.complete
        if params[:type] == nil
            params[:type] = "stata"
          end
          create_and_send_stats_files
        else
          flash[:notice] = "The data extract has not been processed. Please try later."
          respond_to do |format|
            format.html { redirect_to csvarchive_url(@archive) }
          end
        end
    else
      flash[:error] = "You do not have permission to view this data extract"
      respond_to do |format|
        format.html { redirect_to csvarchives_url }
      end
    end
  end
  
  #add a user owned comment to a script and add it to the view
  def add_comment
    @archive = Csvarchive.find(params[:resource_id])
    comment = Comment.new(:words=>params[:words], :user_id=>current_user.id, :commentable_id=>@archive.id, :commentable_type=>"Csvarchive")
    comment.save
    render :partial=>"comments/comment", :locals=>{:comment=>comment}
  end
  
  # you don't like it any more
  def thumbs_down
    extract = Csvarchive.find(params[:id])
    if extract.contributor_id != current_user
      Recommendation.all(:conditions => {:user_id=>current_user.id, :recommendable_id=>extract.id, :recommendable_type=>"Csvarchive"})[0].destroy
      render :update do |page|
          page.replace_html 'recommended', :partial=>"recommendations/thumbs_up", :locals=>{:item=>extract}
          page.replace_html 'award', :partial => "recommendations/awards", :locals => { :count => extract.recommendations.size }
      end
    end
  end
  
  # show that you like a script
  def thumbs_up
    extract = Csvarchive.find(params[:id])
    if extract.contributor_id != current_user
      recommendation = Recommendation.new(:user_id=>current_user.id, :recommendable_id=>extract.id, :recommendable_type=>"Csvarchive")
      recommendation.save
      render :update do |page|
          page.replace_html 'recommended', :partial=>"recommendations/thumbs_down", :locals=>{:item=>extract}
          page.replace_html 'award', :partial => "recommendations/awards", :locals => { :count => extract.recommendations.size }
      end
    end
  end
  
  # check if the extract is complete and if so then update the div
  def check_for_complete
    extract = Csvarchive.find(params[:id])
    if extract.complete
      render :partial=>"csvarchives/check_for_complete"
    else
      render :text=>"still being processed......"
    end
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
      links = Link.find(:all, :conditions => { :subject_type => "Csvarchive", :subject_id => params[:extract_id], :predicate => "link", :user_id => current_user.id })
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
        
        target_links = Link.find(:all, :conditions => { :object_type => "Csvarchive", :object_id => params[:extract_id], :predicate => "link", :user_id => current_user.id })
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
      links = Link.find(:all, :conditions => { :subject_type => "Csvarchive", :subject_id => params[:extract_id], :predicate => "link"})
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
        
        target_links = Link.find(:all, :conditions => { :object_type => "Csvarchive", :object_id => params[:extract_id], :predicate => "link"})
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
    
  def new
    set_parameters_for_sharing_form
    # code that allows 'world' access to extracts or not
    @current_user.cart_items.each do |item|
      variable = Variable.find(item.variable_id)
        if variable.dataset.survey.survey_type.is_ukda
          @ukda_only = true
          break
        end
    end
    @selected_scripts=[]
    @selected_archives=[]
    @selected_surveys=[]
    @scripts = Script.find(:all)
    @scripts=Authorization.authorize_collection("show",@scripts,current_user)
    @surveys = Survey.find(:all)
    #    @surveys=Authorization.authorize_collection("show",@surveys,current_user)
  end

  # The idea here was that if an archive failed to be created on the CSV server side
  # then you could send a request to it to be 're-created'.  However, it is not yet implemented
  def recreate
    logger.info("Recreating archive for " + @archive.filename)
    respond_to do |format|
      format.html { redirect_to csvarchive_path(@archive) }
    end
  end
  
  # GET /csvarchives/
  # Generate array for current_user archives and all archives
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml=>@my_archives, :xml=>@all_archives}
    end
  end

  # GET /csvarchive/1;download
  def download
    # no security here, need some so that people cannot just type in the id
    # and get it if it is 'hidden'
    # firstly check if the current user has the authorization to see the extract
    if Authorization.is_authorized?("download", nil, @archive, current_user)
      # then check the individual surveys to see if any preclude them downloading it
      if check_survey_auth_for_extract
        if params[:type] == nil
          params[:type] = "CSV"
        end

        if @archive.complete
          retrieve_data_extract
          record_download @archive
        else
          flash[:notice] = "The extract is not yet ready for download, please check later"
          respond_to do |format|
            format.html { redirect_to csvarchive_path(@archive) }
          end  
        end
      else
        flash[:error] = "You do not have permission to download some of the survey data within this data extract"
        respond_to do |format|
          format.html { redirect_to csvarchive_path(@archive) }
        end
      end
    else 
      flash[:error] = "You do not have permission to download this data extract"
      respond_to do |format|
        format.html { redirect_to csvarchive_path(@archive) }
      end
    end
  end

  def show
    #    switch on if using web service
    # check_available
    set_parameters_for_sharing_form
    #    check_available
    @sorted_variables = @archive.variables
    # @surveys = @archive.surveys
    # @scripts = Authorization.authorize_collection("show",@archive.scripts,current_user)
    
    source_archives = []
    source_surveys = []
    source_scripts = []
    target_archives = []
    target_surveys = []
    target_scripts = []
    #publications link to something, not from
    @publications = []

    links = Link.find(:all, :conditions => { :subject_type => "Csvarchive", :subject_id => @archive.id, :predicate => "link" })

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
      
    target_links = Link.find(:all, :conditions => { :object_type => "Csvarchive", :object_id => @archive.id, :predicate => "link" })
                                                    
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
    sort_into_datasets @archive
    
    if @archive.contains_nesstar_variables
      create_nesstar_variables_download_urls
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml {render :xml=>@archives}
    end
  end

  def edit
    
    @selected_groups = []
    if @archive.asset.policy.get_settings["sharing_scope"] == Policy::CUSTOM_PERMISSIONS_ONLY 
      @sharing_mode = Policy::CUSTOM_PERMISSIONS_ONLY 
      @archive.asset.policy.permissions.each do |permission|
        if permission.contributor_type == "WorkGroup"
          @selected_groups.push(permission.contributor_id)
        end
      end
    end
    
     @selected_archives = []
      @selected_surveys = []
      @selected_scripts = []
      @selected_publications = []
      #find links where this extract is the source
      links = Link.find(:all, :conditions => { :subject_type => "Csvarchive", :subject_id => @archive.id, :predicate => "link" })

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
    # this is not required any more since the required 'magic' to find sharing_mode is done above
    # set_parameters_for_sharing_form
  end

  def update

    params[:csvarchive][:last_used_at] = Time.now
      
    links = Link.find(:all, 
                                 :conditions => { :subject_type => "Csvarchive", 
                                                  :subject_id => @archive.id,
                                                  :predicate => "link" })

    links.each do |link|
      link.delete
    end
    variable_hash = Hash.new
    @archive.variables.each do |variable|
      if (!variable_hash.has_key?(variable.dataset_id))
        variable_hash[variable.dataset_id] = Array.new
      end
    end
    #add the links again
    selected_surveys = Array.new
    variable_hash.each_key do |dataset_id|
      survey_id = Dataset.find(dataset_id).survey.id
      if !selected_surveys.include?(survey_id)
        selected_surveys.push(survey_id)
      end
    end
    
    save_all_links selected_surveys
    # generate the json encoding for the groups sharing permissions to go in the params
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
      if @archive.update_attributes(params[:csvarchive])
        # the Script was updated successfully, now need to apply updated policy / permissions settings to it
        policy_err_msg = Policy.create_or_update_policy(@archive, current_user, params)

        # update attributions
        Relationship.create_or_update_attributions(@archive, params[:attributions])

        if policy_err_msg.blank?
          flash[:notice] = 'Data Extract metadata was successfully updated.'
          format.html { redirect_to csvarchive_path(@archive) }
        else
          flash[:notice] = "Data Extract metadata was successfully updated. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
          format.html { redirect_to :controller => 'csvarchive', :id => @archive, :action => "edit" }
        end
      else
        format.html {
          set_parameters_for_sharing_form()
          render :action => "edit"
        }
      end
    end
  # end
    # respond_to do |format|
    #   format.html { redirect_to csvarchive_path(@archive) }
    #   format.xml {render :xml=>@archive}
    # end
  end
  
  # PUT /csvarchives/1
  # Send the csv parse request to the server and get the job id back
  # also store all the variables in an array to link to the archive object
  def create

    job_uuid = UUIDTools::UUID.random_create.to_s
    
    params[:archive][:filename] = job_uuid
    params[:archive][:complete] = false
    params[:archive][:last_used_at] = Time.now
    params[:archive][:content_type] = "application/zip"
    params[:archive][:user_id] = current_user.id
    params[:archive][:contributor_type] = "User"
    params[:archive][:contributor_id] = current_user.id

    @archive = Csvarchive.new(params[:archive])
    
    if @archive.save
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
      policy_err_msg = Policy.create_or_update_policy(@archive, current_user, params)
      # update attributions
      Relationship.create_or_update_attributions(@archive, params[:attributions])
      puts "policy error: " + policy_err_msg
    
    # existing_arcs = Csvarchive.find(:all, :conditions=>{:title=> params[:archive][:title], :person_id=>User.find(current_user).person_id})
    #    if existing_arcs.empty?
      all_variables_array = Array.new
      variable_hash = Hash.new
      @current_user.cart_items.each do |item|
        variable = Variable.find(item.variable_id)
        if variable.nesstar_id != nil && @archive.contains_nesstar_variables != true
          @archive.update_attributes(:contains_nesstar_variables => true)
        end
        if (!variable_hash.has_key?(variable.dataset_id))
          variable_hash[variable.dataset_id] = Array.new
        end
        variable_hash[variable.dataset_id].push(item.variable_id)
        all_variables_array.push(Variable.find(item.variable_id))
      end
      @archive.update_attributes({:variables => all_variables_array})
      @archive.variable_lists.each do |variable_list|
        @current_user.cart_items.each do |cart_item|
          if (variable_list.variable_id == cart_item.variable_id)
              variable_list.update_attributes(:search_term => cart_item.search_term, :extract_id => cart_item.extract_id, :user_search_id => cart_item.user_search_id)
            break
          end
        end
      end
      check_nesstar_only variable_hash.keys
    # end
      
      selected_surveys = Array.new
      variable_hash.each_key do |dataset_id|
        survey_id = Dataset.find(dataset_id).survey.id
        if !selected_surveys.include?(survey_id)
          selected_surveys.push(survey_id)
        end
      end
      
      save_all_links selected_surveys
      begin 
        Delayed::Job.enqueue DataExtractJob::StartJobTask.new(variable_hash, current_user.id, @archive.id, @archive.filename, true, base_host)
      rescue Exception => e
        logger.error(e)
      end
      #remove all the variables from the cart since we have now 'bought' them
      current_user.cart_items.each do |item| 
        item.destroy
      end
      respond_to do |format|
        format.html { redirect_to(csvarchive_url(@archive)) }
      end
    else
      #this should be handled by error_messages_for in the view but is not working correctly for this model
      flash[:error] = "Error - you already have a data extract with this title"
      respond_to do |format|
        format.html { redirect_to(new_csvarchive_url) }
      end
    end
  end
  
  # DELETE /csvarchive/1
  def destroy
    find_archive
    #destroy any links to or from this data extract
    links = Link.find(:all, :conditions => { :object_type => "Csvarchive", :object_id => @archive.id, :predicate => "link" })
    links.each do |link|
      link.destroy
    end
    links = Link.find(:all, :conditions => { :subject_type => "Csvarchive", :subject_id => @archive.id, :predicate => "link" })
    links.each do |link|
      link.destroy
    end
    @archive.destroy

    respond_to do |format|
      format.html { redirect_to(csvarchives_url) }
    end
  end
  
  protected
  
  def find_archives_by_page
    @my_page = params[:my_page]
    @all_page = params[:all_page]
    if current_user
      my_archives = Csvarchive.find(:all,
      :order => "created_at DESC",:conditions=>{:user_id => current_user.id})
      @my_archives = my_archives.paginate(:page=>params[:my_page] ? params[:my_page] : 1, :per_page=>default_items_per_page)
    else
      @my_archives = []
    end
    all_archives = Csvarchive.find(:all,
      :order => "created_at DESC")     
    all_authorized_archives = Authorization.authorize_collection("view", all_archives, current_user, keep_nil_records=false)
    @all_archives = all_authorized_archives.paginate(:page=>params[:all_page] ? params[:all_page] : 1, :per_page=>default_items_per_page)
  end

  private
  
  #find out how many variables there are for each dataset
  def sort_into_datasets archive
    @vars_by_dataset = Hash.new
    @total_vars = 0
    archive.variables.each do |variable|
      if !@vars_by_dataset.has_key?(variable.dataset_id.to_s)
        @vars_by_dataset[variable.dataset_id.to_s] = 0
      end
      @vars_by_dataset[variable.dataset_id.to_s] = @vars_by_dataset[variable.dataset_id.to_s] + 1
      @total_vars =  @total_vars + 1
    end
  end
  
  def find_groups
    @groups = WorkGroup.find(:all)
  end
  
  def find_scripts
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

  def find_archives
    @archives = Csvarchive.find(:all)
    @archives=Authorization.authorize_collection("show",@archives,current_user)
  end

  def find_surveys
    @surveys = Survey.find(:all)
    #    @surveys=Authorization.authorize_collection("show",@surveys,current_user)
  end
  
  def find_publications
    @selected_publications = [] unless @selected_publications
    @publications = Publication.all
  end

  def set_parameters_for_sharing_form
    logger.info "setting sharing for archive"
    policy = nil
    policy_type = ""

    # obtain a policy to use
    if defined?(@archive) && @archive.asset
      puts "archive policy exists already"
      if (policy == @archive.asset.policy)
        # Script exists and has a policy associated with it - normal case
        policy_type = "asset"
      else
        #        elsif @script.asset.project && (policy == @script.asset.project.default_policy)
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
      puts "new archive so new default policy"
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
    @resource_type = "Data Extract"
    if current_user
      @favourite_groups = current_user.favourite_groups
    else
      @favourite_groups = []
    end

    @all_people_as_json = Person.get_all_as_json

  end

  def find_archive
    @archive = Csvarchive.find(params[:id])
  end

  def retrieve_data_extract
    begin
      if params[:type] == "Stata"
        path = File.join(CSV_OUTPUT_DIRECTORY, @archive.filename, @archive.filename + "_stata.zip")
        send_file path, :filename => @archive.title.gsub(' ', '_') + "_stata.zip", :content_type => "application/zip", :disposition => 'attachment', :stream => false 
      elsif params[:type] == "SPSS"
        path = File.join(CSV_OUTPUT_DIRECTORY, @archive.filename, @archive.filename + "_spss.zip")
        send_file path, :filename => @archive.title.gsub(' ', '_') + "_spss.zip", :content_type => "application/zip", :disposition => 'attachment', :stream => false        
      else
        path = File.join(CSV_OUTPUT_DIRECTORY, @archive.filename, @archive.filename + "_csv.zip")
        send_file path, :filename => @archive.title.gsub(' ', '_') + "_csv.zip", :content_type => "application/zip", :disposition => 'attachment', :stream => false 
      end
      rescue Exception => e
    end
  end
  
  #save any links to other 'things' for this new data extract
  def save_all_links selected_surveys
    if params[:scripts] != nil
       params[:scripts].each do |script_id|
       link = Link.new
       link.subject = @archive
       link.object = Script.find(script_id)
       link.predicate = "link"
       link.user = current_user
       link.save
       end
     end
     #automatically link from the selected datasets/surveys
     selected_surveys.each do |survey_id|
        link = Link.new
        link.subject = @archive
        link.object = Survey.find(survey_id)
        link.predicate = "link"
        link.user = current_user
        link.save
     end
     if params[:data_extracts] != nil
         params[:data_extracts].each do |extract_id|
            link = Link.new
            link.subject = @archive
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
       link.subject = @archive
       link.object = Publication.find(publication_id)
       link.predicate = "link"
       link.user = current_user
       link.save
       end
     end
  end
  
  # Are there any surveys in this data extract which the 
  # current user does not have permission to download
  def check_survey_auth_for_extract
    auth = true
    ukda = false
    #get a list of all the surveys
    variable_hash = Hash.new
    @archive.variables.each do |variable|
      if (!variable_hash.has_key?(variable.dataset_id))
        variable_hash[variable.dataset_id] = Array.new
      end
    end
    #first thing is see whether the basic auth checks are ok
    #we check for view since the basic premise is that if you can see a survey you can download it
    variable_hash.each_key do |key|
      survey = Dataset.find(key).survey
      if !Authorization.is_authorized?("view", nil, survey, current_user)
        auth = false
        break
      end
    end
    #then we see if there are any ukda surveys lurking in the extract
    variable_hash.each_key do |key|
      survey = Dataset.find(key).survey
      if survey.survey_type.is_ukda
        ukda = true
        break
      end
    end
    #if its a ukda survey then we better see if they are registered
    if ukda
      if current_user != nil
        @ukda_registered = ukda_registration_check(current_user)
      else
        @ukda_registered = false
      end
    end
    
    if ukda && @ukda_registered
      #download ok
      return true
    elsif !ukda && auth
      #download ok
      return true
    else
      #download barred
      return false
    end
  end
  
  # does the current user like this extract
  def recommended_by_current_user
    if current_user
      extract = Csvarchive.find(params[:id])
      e_rec = extract.recommendations
      u_rec = current_user.recommendations
      all_rec =  e_rec & u_rec
      if !all_rec.empty?
        @recommended =  true
      else
        @recommended =  false
      end
    else
      @recommended =  false
    end
  end
  
  #find all the comments for this data extract
  def find_comments
    archive =Csvarchive.find(params[:id])
    @comments = archive.comments
  end
  
  #create stats data files for download
  def create_and_send_stats_files
    if params[:type] == "stata"
      download_stata_files
    else
      download_spss_files
    end
  end
  
  # the request is for stata files, no actual data
  def download_stata_files
    zip_file_path = File.join(CSV_OUTPUT_DIRECTORY, @archive.filename,@archive.filename + "_stata_files_only.zip")
    if !File.exists?(zip_file_path)
      variable_hash = Hash.new
      file_hash = Hash.new
      @archive.variables.each do |variable|
        if (!variable_hash.has_key?(variable.dataset_id))
          variable_hash[variable.dataset_id] = Array.new
        end
        variable_hash[variable.dataset_id].push(variable.id)
      end
      stata_zip_path = File.join(CSV_OUTPUT_DIRECTORY, @archive.filename, @archive.filename + "_stata.zip")
      puts stata_zip_path
      Zip::ZipFile.open(stata_zip_path) {|zipfile|
          variable_hash.each_key do |key|
            dataset = Dataset.find(key)
            if !dataset.nesstar_uri
              file_hash[dataset.name + "_do_file.do"] = zipfile.read(dataset.name + "_do_file.do")
            end
          end
      }
      Zip::ZipFile.open(zip_file_path, Zip::ZipFile::CREATE) {|zipfile|
        zipfile.get_output_stream("metadata.txt") { |f| f.puts @archive.content_blob.data}
        file_hash.each_key do |key|
          puts key
          zipfile.get_output_stream(key) { |f| f.puts file_hash[key] }
        end
      }
    end
      send_file zip_file_path, :filename => @archive.title.gsub(' ', '_') + "_stata_files_only.zip", :content_type => "application/zip", :disposition => 'attachment', :stream => false
  end

  # the request is for spss files, no actual data
  def download_spss_files
    zip_file_path = File.join(CSV_OUTPUT_DIRECTORY, @archive.filename, @archive.filename + "_spss_files_only.zip")
    if !File.exists?(zip_file_path)
      variable_hash = Hash.new
      file_hash = Hash.new
      @archive.variables.each do |variable|
        if (!variable_hash.has_key?(variable.dataset_id))
          variable_hash[variable.dataset_id] = Array.new
        end
          variable_hash[variable.dataset_id].push(variable.id)
      end
      spss_zip_path = File.join(CSV_OUTPUT_DIRECTORY, @archive.filename, @archive.filename + "_spss.zip")
      Zip::ZipFile.open(spss_zip_path) {|zipfile|
        variable_hash.each_key do |key|
          dataset = Dataset.find(key)
          if !dataset.nesstar_uri
            file_hash[dataset.name + "_selection_spss_code.sps"] = zipfile.read(dataset.name + "_selection_spss_code.sps")
          end
        end
      }

      Zip::ZipFile.open(zip_file_path, Zip::ZipFile::CREATE) {|zipfile|
        zipfile.get_output_stream("metadata.txt") { |f| f.puts @archive.content_blob.data}
        file_hash.each_key do |key|
          zipfile.get_output_stream(key) { |f| f.puts file_hash[key] }
        end
      }
    end
    send_file zip_file_path, :filename => @archive.title.gsub(' ', '_') + "_spss_files_only.zip", :content_type => "application/zip", :disposition => 'attachment', :stream => false     
  end
  
  def find_notes
    if current_user
      @extract =Csvarchive.find(params[:id])
      @notes = Note.all(:conditions=>{:notable_type => "Csvarchive", :user_id=>current_user.id, :notable_id => @extract.id})
    end
  end
  
  #create the urls for downloading data extracts from
  #a nesstar server/s
  def create_nesstar_variables_download_urls
    @download_uri_strings = []
    variable_hash = Hash.new
    #figure out what variables are from a nesstar server
    @archive.variables.each do |variable|
      if variable.nesstar_id != nil
        if (!variable_hash.has_key?(variable.dataset_id))
          variable_hash[variable.dataset_id] = Array.new
        end
        variable_hash[variable.dataset_id].push(variable)
      end
    end
    #loop through and create the url for each dataset
    variable_hash.each_key do |dataset_id|
      dataset = Dataset.find(dataset_id)
      download_string = 'format=CSV&execute=true&ddiformat=html&study'
      study_uri = URI.parse(dataset.nesstar_uri)
      study_uri.merge!('/obj/fStudy/' + dataset.nesstar_id)
      puts 'study uri: ' + study_uri.to_s
      study_uri = CGI.escape(study_uri.to_s)
      puts 'study uri: ' + study_uri.to_s
      download_string << '=' + study_uri + '&v=2&analysismode=table&s='
      puts 'download string: ' + download_string.to_s
      variable_hash[dataset_id].each do |variable|
        download_string << CGI.escape(variable.nesstar_id + ',')
      end
      download_string.chomp! #remove the final ,
      download_string << '&mode=download'
      download_uri = URI.join(dataset.nesstar_uri, 'webview/velocity?')
      puts download_uri
      @download_uri_strings << download_uri.to_s + download_string
      
    end
  end
  
  # check an array of dataset ids to see if any
  # are from mb only
  def check_nesstar_only keys
    nesstar = true
    keys.each do |key| 
      if !Dataset.find(key).nesstar_uri
        nesstar = false
        break
      end
    end
    nesstar ? @archive.update_attributes({:nesstar_only => true}) : @archive.update_attributes({:nesstar_only => false})
  end

end
