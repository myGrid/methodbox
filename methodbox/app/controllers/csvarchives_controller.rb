require 'uuidtools'
require 'zip/zip'
require 'zip/zipfilesystem'


class CsvarchivesController < ApplicationController

  before_filter :login_required
  before_filter :find_archives, :only => [ :index ]

  def new
    set_parameters_for_sharing_form
    @scripts = Script.find(:all)
    @scripts=Authorization.authorize_collection("show",@scripts,current_user)
    @surveys = Survey.find(:all)
#    @surveys=Authorization.authorize_collection("show",@surveys,current_user)
  end

  def recreate
    find_archive
    logger.info("Recreating archive for " + @archive.filename)
    respond_to do |format|

      format.html { redirect_to csvarchive_path(@archive) }

    end
  end

  def index
    @all_archives.results =Authorization.authorize_collection("show",@all_archives.results,current_user)
    #    @all_archives.results.each do |item|
    #      if !item.complete
    #        http = Net::HTTP.new('localhost',25000)
    #        http.read_timeout=6000
    #        puts 'sending get request to csv server for file ' + item.filename
    #        #          response = http.get('/eos/download/' + item.filename)
    #        response = http.get(CSV_SERVER_PATH + '/download/' + item.filename)
    #        if response.response.class == Net::HTTPOK
    #          puts 'response 1'
    #          if response.content_type == 'application/zip'
    #            item.update_attributes(:complete => true)
    #
    #          end
    #        elsif response.response.class == Net::HTTPInternalServerError
    #
    #          logger.info( 'archive creation failed ' + item.object_id.to_s)
    #          item.update_attributes(:failure => true)
    #          flash[:error] = "Server reports that CSV archive creation for "  + link_to(item.title, csvarchive_path(:id=>item.id)) + " failed, it is recommended that you recreate it"
    #          #        respond_to do |format|
    #          #          format.html { redirect_to csvarchive_path(@archive) }
    #          #        end
    #        end
    #      end
    #    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml=>@my_archives, :xml=>@all_archives}
    end
  end

  # GET /csvarchive/1;download
  def download
    #    no security here
    find_archive

    if @archive.complete
      retrieve_archive_from_server
    else
      check_available
      if @archive.complete
        retrieve_archive_from_server
      else
        flash[:notice] = "Your data extract is not yet ready for download, please check later"
        respond_to do |format|
          format.html { redirect_to csvarchive_path(@archive) }
        end
      end
      
    end

  end

  def show
    find_archive
    #    switch on if using web service
    check_available
    set_parameters_for_sharing_form
    #    check_available
    @sorted_variables = @archive.variables
    @surveys = @archive.surveys
    @scripts = Authorization.authorize_collection("show",@archive.scripts,current_user)
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
    existing_arcs = Csvarchive.find(:all, :conditions=>"title='" + params[:archive][:title] + "' and person_id=" + User.find(current_user).person_id.to_s)
    if existing_arcs.empty?
    all_variables_array = Array.new
    variable_hash = Hash.new
    params[:all_variables_array].each do |var|
      puts "downloading " + var.to_s
      variable = Variable.find(var)
      if (!variable_hash.has_key?(variable.dataset_id))
        variable_hash[variable.dataset_id] = Array.new
      end
      variable_hash[variable.dataset_id].push(var)
      all_variables_array.push(Variable.find(var))
      #        variable_hash[var] = get_variable(var)
      #        logger.info("Would have downloaded: " + var.to_s)
    end


    #create XML request to be sent with http post request
    doc = XML::Document.new()
    doc.root = XML::Node.new('Datasets')
    root = doc.root
    root << mail = XML::Node.new('Email')
    mail << User.find(current_user.id).person.email

    root << filename = XML::Node.new('Filename')
    filename << params[:archive][:title]
    
    variable_hash.each_key do |key|

      root << dataset = XML::Node.new('Dataset')
      dataset['name']= Dataset.find(key).filename
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
    response = http.post(CSV_SERVER_PATH + '/download', doc.to_s)
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

      #only one script at the moment, change to many in future and can be none
      if params[:script][:id] != ""
        all_scripts_array = Array.new
        all_scripts_array.push(Script.find(params[:script][:id]))
        params[:archive][:scripts] = all_scripts_array
      end
       if params[:survey][:id] != ""
        all_surveys_array = Array.new
        all_surveys_array.push(Survey.find(params[:survey][:id]))
        params[:archive][:surveys] = all_surveys_array
      end
      params[:archive][:filename] = @jobid
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

    end
    
  

    respond_to do |format|

      format.html { redirect_to csvarchive_path(@archive) }

    end
    else
#      respond_to do |format|

      flash[:error] = "You already have an archive with such a title"
  redirect_to(:controller => "csvarchives", :action => "new", :all_variables_array => params[:all_variables_array],:title =>params[:archive][:title], :description => params[:archive][:description])
#    end
  end
  end

  def new_create

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
  
  protected
  
  def find_archives
    @my_page = params[:my_page]
    @all_page = params[:all_page]
    @my_archives = Csvarchive.find(:all,
      :order => "title",:conditions=>"person_id=" + current_user.person_id.to_s, :page=>{:size=>default_items_per_page,:current=>params[:my_page]})
    @all_archives = Csvarchive.find(:all,
      :order => "title",:page=>{:size=>default_items_per_page,:current=>params[:all_page]})
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
        if response.content_type == 'application/zip'
          @archive.update_attributes(:complete => true)
      
        end
        #            elsif response.response.class == Net::HTTPInternalServerError
        #
        #              logger.info( 'archive creation failed ' + @archive.object_id.to_s)
        #              @archive.update_attributes(:failure => true)
        #              flash[:error] = "Server reports that CSV archive creation failed, it is recommended that you recreate it"
        #        respond_to do |format|
        #          format.html { redirect_to csvarchive_path(@archive) }
        #        end
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
    response = http.get(CSV_SERVER_PATH + '/download/' + @archive.filename)
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
          puts "downloading " + var.to_s
          variable = Variable.find(var)
          if (!variable_hash.has_key?(variable.dataset_id))
            variable_hash[variable.dataset_id] = Array.new
          end
          variable_hash[variable.dataset_id].push(var)
          #        variable_hash[var] = get_variable(var)
          #        logger.info("Would have downloaded: " + var.to_s)
        end
        metadata = String.new
        variable_hash.each_key do |key|
          metadata << "\n" + Dataset.find(key).survey.title + "\n---------------"
          metadata << "\n" + Dataset.find(key).name + "\n---------------"
          variable_hash[key].each do |var|
            metadata << "\nName: " + var.name
            metadata << "\nLabel: " + var.value
            if var.category!= nil
              metadata << "\nCategory: " + var.category
            end
            if var.dertype!= nil
              metadata << "\nDerivation Type: " + var.dertype
            end
            if  var.dermethod!= nil
              metadata << "\nDerivation Method: " + var.dermethod
            end
            if var.info!=nil
              metadata << "\nValue Information: " + var.info
            end
            metadata << "\n---------------"
          end
          metadata << "\n\n\n---------------\n---------------"
        end
        Zip::ZipFile.open(RAILS_ROOT + "/" + "filestore" + "/" + @archive.filename  + "/" + uuid+ ".zip", Zip::ZipFile::CREATE) {|zip| zip.get_output_stream("metadata.txt") { |f| f.puts metadata}}
        send_file RAILS_ROOT + "/" + "filestore" + "/" + @archive.filename  + "/" + uuid+ ".zip", :filename => @archive.title + ".zip", :content_type => @archive.content_type, :disposition => 'attachment'

        #        send_data response.body, :filename => "csv.zip", :content_type => @archive.content_type, :disposition => 'attachment'
      end
      #      elsif response.response.class == Net::HTTPInternalServerError
      #
      #        logger.info( 'archive creation failed ' + @archive.object_id.to_s)
      #        @archive.update_attributes(:failure => true)
      #        render :update, :status=>:created do |page|
      #          page.redirect_to(:controller => 'csvarchives', :action => 'show', :id=>@archive.id)
      #        end
    else
      @archive.failure = true
      @archive.save
      flash[:error] = "This data extract is no longer available for download. You are recommended to re-create it"
      respond_to do |format|
        format.html { redirect_to csvarchive_path(@archive) }
      end
    end
  end

end
