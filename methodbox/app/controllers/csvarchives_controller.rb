require 'uuidtools'
require 'zip/zip'
require 'zip/zipfilesystem'


class CsvarchivesController < ApplicationController

  before_filter :login_required, :except => [ :help, :help2]
  before_filter :find_archives_by_page, :only => [ :index]
  before_filter :find_scripts, :find_surveys, :find_archives, :find_groups, :find_publications, :only => [ :new,:edit ]
  before_filter :find_archive, :only => [ :edit, :update, :show, :recreate, :download ]
  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]

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
    if params[:type] == nil
      params[:type] = "CSV"
    end
    # this download info should be logged somewhere
    # puts "type is " + params[:type]

    if @archive.complete
      retrieve_archive_from_server
      record_download @archive
    else
      check_available
      if @archive.complete
        retrieve_archive_from_server
        record_download @archive
      else
        flash[:notice] = "Your data extract is not yet ready for download, please check later"
        respond_to do |format|
          format.html { redirect_to csvarchive_path(@archive) }
        end
      end
      
    end

  end

  def show
    #    switch on if using web service
    check_available
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
    #add the links again
    if params[:scripts] != nil
      # all_scripts_array = Array.new
      params[:scripts].each do |script_id|
      link = Link.new
      link.subject = @archive
      link.object = Script.find(script_id)
      link.predicate = "link"
      link.user = current_user
      link.save
      end
    end
    if params[:surveys] != nil
        params[:surveys].each do |survey_id|
           link = Link.new
           link.subject = @archive
           link.object = Survey.find(survey_id)
           link.predicate = "link"
           link.user = current_user
           link.save
        end
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
        params[:publications].each do |publication_id|
        link = Link.new
        link.subject = @archive
        link.object = Publication.find(publication_id)
        link.predicate = "link"
        link.user = current_user
        link.save
        end
      end
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

    existing_arcs = Csvarchive.find(:all, :conditions=>"title='" + params[:archive][:title] + "' and person_id=" + User.find(current_user).person_id.to_s)
    if existing_arcs.empty?
      all_variables_array = Array.new
      variable_hash = Hash.new
      @current_user.cart_items.each do |item|
        # puts "downloading " + item.variable_id.to_s
        variable = Variable.find(item.variable_id)
        if (!variable_hash.has_key?(variable.dataset_id))
          variable_hash[variable.dataset_id] = Array.new
        end
        variable_hash[variable.dataset_id].push(item.variable_id)
        all_variables_array.push(Variable.find(item.variable_id))
      end
      
      selected_surveys = Array.new
      variable_hash.each_key do |dataset_id|
        survey_id = Dataset.find(dataset_id).survey.id
        if !selected_surveys.include?(survey_id)
          selected_surveys.push(survey_id)
        end
      end

      #create XML request to be sent with http post request
      doc = create_request_document variable_hash

      logger.info doc

      # create temporary file with xmlrequest inside
      f = Tempfile.new(UUIDTools::UUID.random_create.to_s)
      f << doc.to_s
      f.flush
      request_path = 'http://' + CSV_SERVER_LOCATION + ':' + CSV_SERVER_PORT  + CSV_SERVER_PATH + '/download'

      response = RestClient.post request_path, :datasetrequest => File.new(f.path, 'rb') 
      # {|response, request, &block|
        #delete the temp file
        f.close
        # puts response
        case response.code
          when 200
            process_response response, all_variables_array, variable_hash, selected_surveys
          respond_to do |format|
            format.html { redirect_to csvarchive_path(@archive) }
          end
        else
          flash[:error] = "An error occurred during creation. The MethodBox team are investigating the problem.\nSorry for any inconvenience."
          redirect_to csvarchives_url
        end
      else
        flash[:error] = "You already have an archive with such a title"
        redirect_to(:controller => "csvarchives", :action => "new", :all_variables_array => params[:all_variables_array],:title =>params[:archive][:title], :description => params[:archive][:description])
      end
  end

  # some experimental code for creating the archive on the rails side.
  # would need a lot of work due to threading etc.
  # DO NOT USE!
  def new_create

    #     send the csv parse request to the server and get the job id back
    #a hash, each key is a particular survey, the value is the variable
    #      also store all the variables in an array to add to the archive object
    #      variable_hash = Hash.new
    all_variables_array = Array.new
    variable_hash = Hash.new
    params[:all_variables_array].each do |var|
      # puts "downloading " + var.to_s
      variable = Variable.find(var)
      if (!variable_hash.has_key?(variable.survey_id))
        variable_hash[variable.survey_id] = Array.new
      end
      variable_hash[variable.survey_id].push(var)
      all_variables_array.push(Variable.find(var))
      #        variable_hash[var] = get_variable(var)
      #        logger.info("Would have downloaded: " + var.to_s)
    end
    file_uuid = UUIDTools::UUID.random_create.to_s
    puts "uuid is " + file_uuid.to_s
    params[:archive][:filename] = file_uuid
    params[:archive][:complete] = false
    params[:archive][:last_used_at] = Time.now
    #      @archive.content_blob = ContentBlob.new(:data => file.body)
    params[:archive][:content_type] = "application/zip"
    params[:archive][:person_id] = User.find(current_user.id).person.id
    params[:archive][:variables] = all_variables_array
    params[:archive][:contributor_type] = "User"
    params[:archive][:contributor_id] = current_user.id
    @archive = Csvarchive.new(params[:archive])
    @archive.save

    policy_err_msg = Policy.create_or_update_policy(@archive, current_user, params)

    # update attributions
    Relationship.create_or_update_attributions(@archive, params[:attributions])
    puts "policy error: " + policy_err_msg

    #Process the archive in a separate thread
    Thread.new() do
      puts "starting thread"
      file_names = Array.new
      variable_hash.each_key do |key|
        puts "processing " + key
        dataset_name= Survey.find(key).original_filename
        puts "looking for " + Survey.find(key).original_filename
        infile = File.open(CSV_FILE_PATH + "/" + dataset_name)
        puts "opened file"
        uuid = UUIDTools::UUID.random_create.to_s
        csv_file_name = Survey.find(key).name + "_" + uuid + ".csv"
        puts "new csv file is " + csv_file_name
        file_names.push(csv_file_name)
        outfile= File.new(NEW_CSV_FILE_PATH + "/" + csv_file_name)
        puts "full path is " + outfile
        i=0
        pos = Array.new
        csv_arr = Array.new
        CSVScan.scan(infile) { |row| line = FCSV.parse(row[0], :col_sep => "\t"); new_row = Array.new; if i==0: variable_hash[key].each {|var| pos.push(line[0].rindex(var))} end; i=i+1; pos.each {|col| val = line[0][col];new_row.push(val)}; csv_arr.push(new_row)}
        puts "scanned file"
        infile.close
        FasterCSV.open(outfile, "w") do |csv_file| csv_arr.each {|csv| csv_file << csv} end
        puts "created new file"
        outfile.close
      end
      #create the zip file

      zip_file_name = File.join(RAILS_ROOT,"filestore", "csv_files", file_uuid + ".zip")
      puts "zip file will be " + zip_file_name
      
      Zip::ZipFile.open(zip_file_name, Zip::ZipFile::CREATE) {
        |zipfile|
        file_names.each {
          |file_name|
          puts "adding file to zip " + file_name
          zipfile.add(file_name, NEW_CSV_FILE_PATH + "/" + file_name + ".csv")
          puts "added"

        }
      }
      
      #the csv has been parsed and the new archive is complete
      @archive.complete = true
      @archive.save
    end

    respond_to do |format|

      format.html { redirect_to csvarchive_path(@archive) }

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
    my_archives = Csvarchive.find(:all,
      :order => "created_at DESC",:conditions=>"person_id=" + current_user.person_id.to_s)
    @my_archives = my_archives.paginate(:page=>params[:my_page] ? params[:my_page] : 1, :per_page=>default_items_per_page)
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
    @favourite_groups = current_user.favourite_groups

    @all_people_as_json = Person.get_all_as_json

  end
  

  def check_available
    if !@archive.complete
      http = Net::HTTP.new('localhost',25000)
      http.read_timeout=6000
      puts 'sending get request to csv server for file ' + @archive.filename
      #      response = http.get('/eos/download/' + @archive.filename)
      response = http.get(CSV_SERVER_PATH + '/download/' + @archive.filename+ '?type=CSV')
      if response.response.class == Net::HTTPOK
        if response.content_type == 'application/zip'
          @archive.update_attributes(:complete => true)
      
        end
      end
    end
  end
  
  

  def find_archive
    @archive = Csvarchive.find(params[:id])
  end

  def retrieve_archive_from_server
    puts 'sending get request to csv server for file ' + @archive.filename

    http = Net::HTTP.new(CSV_SERVER_LOCATION,CSV_SERVER_PORT.to_i)
    http.read_timeout=6000
    stata_download = false
    #a stata download is the csv plus the do file it needs to load in the metadata
    if params[:type] == "Stata"
      stata_download = true
      params[:type] = "CSV"
    end
    
    response = http.get(CSV_SERVER_PATH + '/download/' + @archive.filename + "?type=" + params[:type])
    if response.response.class == Net::HTTPOK
      if response.content_type == 'application/zip'
        logger.info( 'file ready, archive id ' + @archive.object_id.to_s)
        uuid = UUIDTools::UUID.random_create.to_s
        #create directory and zip file for the archive
        File.makedirs(RAILS_ROOT + "/" + "filestore" + "/" + @archive.filename)
        uf = File.open(RAILS_ROOT + "/" + "filestore" + "/" + @archive.filename  + "/" + uuid+ ".zip","w")
        uf.write(response.body)
        uf.close
        
        variable_hash = Hash.new
        @archive.variables.each do |var|
          # puts "downloading " + var.to_s
          variable = Variable.find(var)
          if (!variable_hash.has_key?(variable.dataset_id))
            variable_hash[variable.dataset_id] = Array.new
          end
          variable_hash[variable.dataset_id].push(var)
          #        variable_hash[var] = get_variable(var)
          #        logger.info("Would have downloaded: " + var.to_s)
        end
        if @archive.content_blob == nil
 
        metadata = String.new
          variable_hash.each_key do |key|
            metadata << "\r\n" + Dataset.find(key).survey.title + "\r\n---------------"
            metadata << "\r\n" + Dataset.find(key).name + "\r\n---------------"
            variable_hash[key].each do |var|
              metadata << "\r\nName: " + var.name
              if var.value != nil
                metadata << "\r\nLabel: " + var.value
              end
              if var.category!= nil
                metadata << "\r\nCategory: " + var.category
              end
              if var.dertype!= nil
                metadata << "\r\nDerivation Type: " + var.dertype
              end
              if  var.dermethod!= nil
                metadata << "\r\nDerivation Method: " + var.dermethod.gsub("\n", "\r\n")
              end
              if var.info!=nil
                metadata << "\r\nValue Information: " + var.info.gsub("\n", "\r\n")
              end
              metadata << "\r\n---------------"
            end
            metadata << "\r\n\r\n\r\n---------------\r\n---------------"
          end
          content_blob = ContentBlob.new(:data => metadata)
          @archive.update_attributes(:content_blob=>content_blob)
        end
        
        if stata_download
          @archive.stata_do_files.each do |do_file|
            Zip::ZipFile.open(RAILS_ROOT + "/" + "filestore" + "/" + @archive.filename  + "/" + uuid+ ".zip", Zip::ZipFile::CREATE) {|zip| zip.get_output_stream(do_file.name) { |f| f.puts do_file.data}}
            
          end
        end
        
        Zip::ZipFile.open(RAILS_ROOT + "/" + "filestore" + "/" + @archive.filename  + "/" + uuid+ ".zip", Zip::ZipFile::CREATE) {|zip| zip.get_output_stream("metadata.txt") { |f| f.puts @archive.content_blob.data}}
        begin
          if stata_download
            send_file RAILS_ROOT + "/" + "filestore" + "/" + @archive.filename  + "/" + uuid+ ".zip", :filename => @archive.title + "_stata.zip", :content_type => "application/zip", :disposition => 'attachment', :stream => false 
          else  
            send_file RAILS_ROOT + "/" + "filestore" + "/" + @archive.filename  + "/" + uuid+ ".zip", :filename => @archive.title + "_" + params[:type] + ".zip", :content_type => "application/zip", :disposition => 'attachment', :stream => false 
          end
        rescue Exception => e
          
        ensure
        File.delete(RAILS_ROOT + "/" + "filestore" + "/" + @archive.filename  + "/" + uuid+ ".zip")
          
        end
      end
    elsif params[:type]!="CSV"
      flash[:notice] = "This data extract is only available in CSV format."
       respond_to do |format|
          format.html { redirect_to csvarchive_path(@archive) }
        end
    else
      @archive.failure = true
      @archive.save
      flash[:error] = "This data extract is no longer available for download. You are recommended to re-create it"
      respond_to do |format|
        format.html { redirect_to csvarchive_path(@archive) }
      end
    end
  end
  
  #create the xml request for the csv server for this
  #new data extract
  def create_request_document variable_hash
    doc = XML::Document.new()
    doc.root = XML::Node.new('Datasets')
    root = doc.root
    root << mail = XML::Node.new('Email')
    mail << User.find(current_user.id).person.email

    root << filename = XML::Node.new('Filename')
    filename << params[:archive][:title]
  
    variable_hash.each_key do |key|

      root << dataset = XML::Node.new('Dataset')
      dataset['datasetname'] = Dataset.find(key).name
      dataset['name']= Dataset.find(key).uuid_filename
      dataset['year']= Survey.find(Dataset.find(key).survey_id).year
      dataset['survey']= Survey.find(Dataset.find(key).survey_id).survey_type.shortname
      dataset << variables = XML::Node.new('Variables')
      variable_hash[key].each do |var|
        variables << variable = XML::Node.new('Variable')
        variable << Variable.find(var).name
      end
    end
    return doc
  end
  
  #create the metadata file for this new extract
  def create_metadata_file variable_hash
    metadata = String.new
     variable_hash.each_key do |key|
       metadata << "\r\n" + Dataset.find(key).survey.title + "\r\n---------------"
       metadata << "\r\n" + Dataset.find(key).name + "\r\n---------------"
       variable_hash[key].each do |var|
         variable = Variable.find(var)
         metadata << "\r\nName: " + variable.name
         if variable.value != nil
           metadata << "\r\nLabel: " + variable.value
         end
         if variable.category!= nil
           metadata << "\r\nCategory: " + variable.category
         end
         if variable.dertype!= nil
           metadata << "\r\nDerivation Type: " + variable.dertype
         end
         if  variable.dermethod!= nil
           metadata << "\r\nDerivation Method: " + variable.dermethod.gsub("\n", "\r\n")
         end
         if variable.info!=nil
           metadata << "\r\nValue Information: " + variable.info.gsub("\n", "\r\n")
         end
         metadata << "\r\n---------------"
       end
       metadata << "\r\n\r\n\r\n---------------\r\n---------------"
     end
     return metadata
  end
  
  #create stata do files for this new extract
  def create_stata_do_files variable_hash
    do_file_hash = Hash.new
    variable_hash.each_key do |key|
      d = Dataset.find(key)
      do_file = String.new
      do_file << "***Extract title:  " + params[:archive][:title] + "\r\n"
      do_file << "*** " + d.name + " (dataset)\r\n"
      do_file << "*** " + d.survey.title + " (survey)\r\n"
      do_file << "version" + STATA_VERSION + "\r\nset more off\r\n"
      do_file << "insheet using \""  + d.name.split(".")[0] + "_selection.csv\", clear\r\n\r\n"
      do_file << "***Variables\r\n\r\n"
      variable_hash[key].each do |var|
        variable = Variable.find(var)
          do_file << "*" + variable.name + "\r\n"
          do_file << "label var " + variable.name + " " + "\"" + variable.value + "\"\r\n"
          if !variable.value_domains.empty?
            val_doms = String.new
            variable.value_domains.each do |value_domain|
             
            val_doms << value_domain.value + " \"" + value_domain.label + "\" "
            end
            do_file << "label define " + variable.name + "_value_domain " + val_doms +"\r\n"
            do_file << "label value " + variable.name + " " + variable.name + "_value_domain\r\n\r\n"
          else 
            do_file << "\r\n"
          end
      end
      #finally stick the do file in the hash
      # puts do_file
      do_file_hash[key] = do_file
    end
    return do_file_hash
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
  
  #process the response to the create archive request from the csv server
  def process_response response, all_variables_array, variable_hash, selected_surveys
      xmlstring = String.new
      # response.body.each do |str|
        xmlstring = response
      # end    

      logger.info xmlstring
      xmlparser = XML::Parser.string(xmlstring)
      xmldoc = xmlparser.parse
      root = xmldoc.root
      @jobid = root.child.to_s
  
      # create metadata file and save it to the db 
      metadata = create_metadata_file variable_hash
    
      #create a hash map containing the stata do files
      do_file_hash = create_stata_do_files variable_hash

      params[:archive][:filename] = @jobid
      params[:archive][:complete] = false
      params[:archive][:last_used_at] = Time.now
      params[:archive][:content_type] = "application/zip"
      params[:archive][:person_id] = User.find(current_user.id).person.id
      params[:archive][:variables] = all_variables_array
      params[:archive][:contributor_type] = "User"
      params[:archive][:contributor_id] = current_user.id

      @archive = Csvarchive.new(params[:archive])
      @archive.content_blob = ContentBlob.new(:data => metadata)
      @archive.save
      do_file_hash.each_key do |key|
        stata_do_file = StataDoFile.new
        stata_do_file.name = Dataset.find(key).name + "_do_file.txt"
        stata_do_file.csvarchive = @archive
        stata_do_file.data = do_file_hash[key]
        stata_do_file.save
      end
  
      #we now have an id for the extract so save all of its links with other things
      save_all_links selected_surveys
    
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
  end

end
