class CsvarchivesController < ApplicationController

  before_filter :login_required
  before_filter :find_archives, :only => [ :index ]

  def new
    set_parameters_for_sharing_form
  end

  def recreate
    find_archive
    logger.info("Recreating archive for " + @archive.filename)
    respond_to do |format|

      format.html { redirect_to csvarchive_path(@archive) }

    end
  end

  def index
    @archives=Authorization.authorize_collection("show",@archives,current_user)
    @archives.each do |item|
      if !item.complete
         http = Net::HTTP.new('localhost',25000)
          http.read_timeout=6000
          puts 'sending get request to csv server for file ' + item.filename
#          response = http.get('/eos/download/' + item.filename)
          response = http.get(CSV_SERVER_PATH + '/download/' + item.filename)
          if response.response.class == Net::HTTPOK
            puts 'response 1'
            if response.content_type == 'application/zip'
              item.update_attributes(:complete => true)

            end
          elsif response.response.class == Net::HTTPInternalServerError

            logger.info( 'archive creation failed ' + item.object_id.to_s)
            item.update_attributes(:failure => true)
            flash[:error] = "Server reports that CSV archive creation for "  + link_to(item.title, csvarchive_path(:id=>item.id)) + " failed, it is recommended that you recreate it"
            #        respond_to do |format|
            #          format.html { redirect_to csvarchive_path(@archive) }
            #        end
          end
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml=>@archives}
    end
  end

  # GET /csvarchive/1;download
  def download
    #    no security here
    find_archive
    #    set_parameters_for_sharing_form
    check_available
#    http = Net::HTTP.new('localhost', 25000)
    http = Net::HTTP.new(CSV_SERVER_LOCATION,CSV_SERVER_PORT.to_i)
    http.read_timeout=6000
    puts 'sending get request to csv server for file ' + @archive.filename
    if @archive.complete
#      response = http.get('/eos/download/' + @archive.filename)
      response = http.get(CSV_SERVER_PATH + '/download/' + @archive.filename)
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
    set_parameters_for_sharing_form
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

  def update
    find_archive
    puts "would have updated"
    respond_to do |format|
      format.html { redirect_to csvarchive_path(@archive) }
      format.xml {render :xml=>@archive}
    end
  end
  
  # PUT /csvarchives/1
  def create

    #     send the csv parse request to the server and get the job id back
    #a hash, each key is a particular survey, the value is the variable
    #      also store all the variables in an array to add to the archive object
    #      variable_hash = Hash.new
    all_variables_array = Array.new
    variable_hash = Hash.new
    params[:all_variables_array].each do |var|
      puts "downloading " + var.to_s
      variable = Variable.find(var)
      if (!variable_hash.has_key?(variable.survey_id))
        variable_hash[variable.survey_id] = Array.new
      end
      variable_hash[variable.survey_id].push(var)
      all_variables_array.push(Variable.find(var))
      #        variable_hash[var] = get_variable(var)
      #        logger.info("Would have downloaded: " + var.to_s)
    end


    #create XML request to be sent with http post request
    doc = XML::Document.new()
    doc.root = XML::Node.new('Datasets')
    root = doc.root

    variable_hash.each_key do |key|

      root << dataset = XML::Node.new('Dataset')
      dataset['name']= Survey.find(key).original_filename
      dataset << variables = XML::Node.new('Variables')
      variable_hash[key].each do |var|
        variables << variable = XML::Node.new('Variable')
        variable << Variable.find(var).name
      end
    end

    http = Net::HTTP.new('localhost',25000)
    http.read_timeout=6000
#    response = http.post('/eos/download', doc.to_s)
    puts doc.to_s
    response = http.post(CSV_SERVER_PATH + '/download/', doc.to_s)
    if response.response.class == Net::HTTPOK
      xmlstring = String.new
      response.body.each do |str|
        xmlstring = xmlstring + str
      end
      puts xmlstring
      xmlparser = XML::Parser.string(xmlstring)
      xmldoc = xmlparser.parse
      root = xmldoc.root
      @jobid = root.child.to_s

      
      params[:archive][:filename] = @jobid
      params[:archive][:complete] = false
      params[:archive][:last_used_at] = Time.now
      #      @archive.content_blob = ContentBlob.new(:data => file.body)
      params[:archive][:content_type] = "application/zip"
      params[:archive][:person_id] = current_user.id
      params[:archive][:variables] = all_variables_array
      params[:archive][:contributor_type] = "User"
      params[:archive][:contributor_id] = current_user.id
      @archive = Csvarchive.new(params[:archive])
      @archive.save
      
      policy_err_msg = Policy.create_or_update_policy(@archive, current_user, params)

      # update attributions
      Relationship.create_or_update_attributions(@archive, params[:attributions])
      puts "policy error: " + policy_err_msg

    end
    
  

    respond_to do |format|

      format.html { redirect_to csvarchive_path(@archive) }

    end
  end
  
  protected
  
  def find_archives
    found = Csvarchive.find(:all,
      :order => "title")

    @archives = found
  end

  private

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
    @resource_type = "CSV Archive"
    @favourite_groups = current_user.favourite_groups

    @all_people_as_json = Person.get_all_as_json

  end
  

  def check_available
    if !@archive.complete
      http = Net::HTTP.new('localhost',25000)
      http.read_timeout=6000
      puts 'sending get request to csv server for file ' + @archive.filename
#      response = http.get('/eos/download/' + @archive.filename)
      response = http.get(CSV_SERVER_PATH + '/download/' + @archive.filename)
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
