class CsvarchivesController < ApplicationController

  before_filter :login_required

  def recreate
    find_archive
    logger.info("Recreating archive for " + @archive.filename)
    respond_to do |format|

      format.html { redirect_to csvarchive_path(@archive) }

    end
  end

  # GET /csvarchive/1;download
  def download
    #    no security here
    find_archive
    check_available
    http = Net::HTTP.new('localhost',25000)
    http.read_timeout=6000
    puts 'sending get request to csv server for file ' + @archive.filename
    if @archive.complete
      response = http.get('/eos/download/' + @archive.filename)
      if response.response.class == Net::HTTPOK
        if response.content_type == 'application/zip'
          logger.info( 'file ready, archive id ' + @archive.object_id.to_s)
          send_data response.body, :filename => "csv.zip", :content_type => @archive.content_type, :disposition => 'attachment'
        end
        #      elsif response.response.class == Net::HTTPInternalServerError
        #
        #        logger.info( 'archive creation failed ' + @archive.object_id.to_s)
        #        @archive.update_attributes(:failure => true)
        #        render :update, :status=>:created do |page|
        #          page.redirect_to(:controller => 'csvarchives', :action => 'show', :id=>@archive.id)
        #        end
      end
    end

    @archive.last_used_at = Time.now

  end

  def show
    find_archive
    
    check_available
    @sorted_variables = @archive.variables
    respond_to do |format|
      format.html # show.html.erb
      format.xml {render :xml=>@archives}
    end
  end

  def edit
    find_archive
    set_parameters_for_sharing_form
  end
  
  # PUT /csvarchives/1
  def update
    find_archive
    
    params[:csvarchive][:last_used_at] = Time.now

    respond_to do |format|
      @archive.update_attributes(params[:csvarchive])

      format.html { redirect_to csvarchive_path(@archive) }

    end
  end

  private

  def set_parameters_for_sharing_form

    logger.info "creating policy for archive"
    policy = nil
    policy_type = ""

    # obtain a policy to use

    policy_type = "project"


    unless policy
      # several scenarios could lead to this point:
      # 1) this is a "new" action - no Datafile exists yet; use default policy:
      #    - if current user is associated with only one project - use that project's default policy;
      #    - if current user is associated with many projects - use system default one;
      # 2) this is "edit" action - Datafile exists, but policy wasn't attached to it;
      #    (also, Datafile wasn't attached to a project or that project didn't have a default policy) --
      #    hence, try to obtain a default policy for the contributor (i.e. owner of the Datafile) OR system default
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
    @resource_type = "CSV Archive"
    @favourite_groups = current_user.favourite_groups

    @all_people_as_json = Person.get_all_as_json


  end

  def check_available
    if !@archive.complete
      http = Net::HTTP.new('localhost',25000)
      http.read_timeout=6000
      puts 'sending get request to csv server for file ' + @archive.filename
      response = http.get('/eos/download/' + @archive.filename)
      if response.response.class == Net::HTTPOK
        puts 'response 1'
        if response.content_type == 'application/zip'
          @archive.update_attributes(:complete => true)

        end
      elsif response.response.class == Net::HTTPInternalServerError

        logger.info( 'archive creation failed ' + @archive.object_id.to_s)
        @archive.update_attributes(:failure => true)
        flash[:error] = "Server reports that CSV archive creation failed, it is recommended that you recreate it"
        #        respond_to do |format|
        #          format.html { redirect_to csvarchive_path(@archive) }
        #        end
      end
    end
  end

  def find_archive
    @archive = Csvarchive.find(params[:id])
  end
end