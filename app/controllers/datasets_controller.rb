require 'rest_client'
require 'uuidtools'
#require 'simple-spreadsheet-extractor'

class DatasetsController < ApplicationController

  include ProcessDatasetJob
  #include SysMODB::SpreadsheetExtractor

  # before_filter :is_user_admin_auth, :only =>[ :new, :create, :edit, :update, :update_data, :update_metadata, :load_new_data, :load_new_metadata]
  before_filter :authorize_new, :only => [ :new, :create ]
  before_filter :login_required, :except => [ :show ]
  before_filter :find_datasets, :only => [ :index ]
  before_filter :find_dataset, :only => [ :show, :edit, :update, :update_data, :update_metadata, :load_new_data, :load_new_metadata ]
  before_filter :can_add_or_edit_datasets, :only => [ :edit, :load_new_data, :load_new_metadata, :update ]
  after_filter  :update_last_user_activity
  before_filter :find_previous_searches, :only => [ :show ]
  
  #update the datafile for this dataset
  def load_new_data
    begin
      new_dataset_version = @dataset.current_version + 1
      old_reason_for_update = @dataset.reason_for_update
      old_updated_by = @dataset.updated_by
      old_filename = @dataset.filename
      old_uuid_filename = @dataset.uuid_filename
      old_current_version = @dataset.current_version
      old_has_data = @dataset.has_data
      uuid = UUIDTools::UUID.random_create.to_s
      #create directory and zip file for the archive
      filename = CSV_FILE_PATH + "/" + uuid + ".data"
      uf = File.open(filename,"w")
      if params[:dataset_format] == "Excel"
        uf.write(spreadsheet_to_csv(params[:file][:data],"1"))
      else
        params[:file][:data].each_line do |line|                
          uf.write(line)
        end
      end
      uf.close
    
      if check_datafile_ok filename
        @dataset.update_attributes(:reason_for_update=>params[:update][:reason], :updated_by=>current_user.id, :filename=>params[:file][:data].original_filename, :uuid_filename=> uuid + ".data", :current_version => new_dataset_version, :has_data=>true)
        load_new_dataset filename
        expire_survey_cache
        respond_to do |format|
          flash[:notice] = "New data file was applied to dataset"
          format.html
        end
      else
        respond_to do |format|
          flash[:error] = @datafile_error
          format.html { redirect_to dataset_path(@dataset) }
        end
      end
    rescue Exception => e
      logger.error(Time.now.to_s + " " + e)
      @dataset.update_attributes(:reason_for_update=>old_reason_for_update, :updated_by=>old_updated_by, :filename=>old_filename, :uuid_filename=> old_uuid_filename, :current_version => old_current_version,:has_data=>old_has_data)
      respond_to do |format|
        flash[:error] = "There was a problem updating the dataset. Please try again. The error was: " + e
        format.html { redirect_to dataset_path(@dataset) }
      end
    end
  end
  
  #update the metadata for this dataset
  def load_new_metadata
    if @dataset.has_data != nil
      uuid = UUIDTools::UUID.random_create.to_s
      filename = File.join(METADATA_PATH, uuid + ".xml")
      uf = File.open(filename,"w")
      params[:file][:metadata].each_line do |line|                
        uf.write(line)
      end
      uf.close
      #first check mime type
#TODO This will not work on windows since it depends on the unix tool file need to use a different way. Possible begin/rescue it so that
#failure does not matter
      mimetype = `file --mime -br #{filename}`.gsub(/\n/,"").split(';')[0]
     # if mimetype.index("xml") == nil && mimetype.index("XML") == nil
      #  possible_mimetype = `file -b #{filename}`
       # respond_to do |format|
        #  flash[:error] = "MethodBox cannot process this file.  Is it really an xml file? Checking the mime type revealed this: " + possible_mimetype
         # format.html { redirect_to dataset_path(@dataset) }
        #end
     # else  
        begin 
          logger.info(Time.now.to_s + " Starting metadata processing job for " + @dataset.id.to_s + " user " + current_user.id.to_s)
          Delayed::Job.enqueue ProcessMetadataJob::StartJobTask.new(@dataset.id, current_user.id, params[:dataset_metadata_format], uf.path, params[:update][:reason], base_host)
        rescue Exception => e
          logger.error(Time.now.to_s + " " + e)
          raise e
        end   
        respond_to do |format|
          flash[:notice] = "The metadata is being updated. You will be emailed when it is ready."  
          format.html { redirect_to dataset_path(@dataset) }
        end
      #end
    else
      respond_to do |format|
        flash[:error] = "There are no variables in this dataset.  Please upload a dataset file."
        format.html { redirect_to dataset_path(@dataset) }
      end
    end
  end
  
  def update_data

  end
  
  def update_metadata
   
  end

  def index

  end

  def show
    
  end
  
  def new
    @survey = Survey.find(params[:survey])
  end
  
  def create
    begin
      uuid = UUIDTools::UUID.random_create.to_s
      #write out the dataset into a new file
      filename=File.join(CSV_FILE_PATH, uuid + ".data")
      uf = File.open(filename,"w")
      if params[:dataset_format] == "Excel"
	#convert the file to csv before writing out
	uf.write(spreadsheet_to_csv(params[:dataset][:data],"1"))
      else
        params[:dataset][:data].each_line do |line|                
          uf.write(line)
        end
      end
      uf.close
      
      @survey = Survey.find(params[:dataset][:survey])
      if check_datafile_ok filename
        dataset = Dataset.new
        dataset.current_version = 1
        dataset.survey = @survey
        dataset.name = params[:dataset][:title]
        dataset.description = params[:dataset][:description]
        dataset.filename = params[:dataset][:data].original_filename
        dataset.uuid_filename = uuid + ".data"
        dataset.save
        load_dataset filename, dataset
        dataset.update_attributes(:has_metadata=>false)
        @dataset = dataset
        respond_to do |format|
          format.html { redirect_to dataset_path(@dataset) }
        end
      else
        respond_to do |format|
          flash[:error] = @datafile_error
          format.html { redirect_to survey_path(@survey) }
        end
      end

    rescue Exception => e
      logger.error(Time.now.to_s + " " + e)
       respond_to do |format|
          flash[:error] = "There was a problem creating this dataset.  Please try again.  The error was: " + e
          format.html { redirect_to survey_path(@survey) }
        end
    end
    
  end
  
  def edit

  end
  
  def update
    
    if @dataset.update_attributes(params[:dataset])
      respond_to do |format|
        format.html { redirect_to dataset_path(@dataset) }
      end
    else
      respond_to do |format|
        flash[:error] = "There was an error while processing this update"
        format.html { redirect_to dataset_path(@dataset) }
      end
    end
  end

  private

  def find_dataset
    @dataset = Dataset.find(params[:id])
  end

  def find_datasets
    @datasets = Dataset.all
  end
  
  private
  
  def update_dataset
    if params[:dataset_format] == "Excel"

    end
    header =  params[:file][:data].readline
    #split by tab
    if params[:dataset_format] == "Tab Separated"
        headers = header.split("\t")
    else
        headers = header.split(",")
    end
    #Look at existing vars, find the differences - could be quite slow I guess?
    #need to find variables which are missing from the existing set and variables which are 'new'
    all_var = Variable.all(:conditions=> {:dataset_id => @dataset.id, :is_archived=>false}, :select => "name")

    all_variables = Array.new(all_var.size){|i| all_var[i].name}
    
    #find out the variables that are missing from the new dataset
    missing_variables = all_variables.collect {|orig_var| !headers.include?(orig_var)}
    #find out the variables that are new
    new_vars = headers.collect{|header_var| !all_var.include?(header_var)}
    
    @new_variables = []
    #add any new variables to the dataset
    headers.each do |var|
      if new_vars.include?(var)  
        variable = Variable.new
        variable.name = var
        variable.dataset = @dataset
        variable.save
        logger.info(Time.now.to_s + " This was new " + variable.name)
        @new_variables.push(variable)
      end
    end
  end
  
  #Load the first CSV/Tabbed file for a survey.
  #Create the variables from the header line
  def load_dataset filename, dataset
    datafile = File.open(filename, "r")
    @new_variables =[]
    #split by tab
    if params[:dataset_format] == "Tab Separated"
	separator = "\t"
	faster_csv_file = FCSV.new(datafile, :headers=>true, :return_headers=>true, :col_sep => separator)
        all_headers = faster_csv_file.shift
	headers = all_headers.headers
    #split by comma
    elsif params[:dataset_format] == "Comma Separated"
	separator = ','
	faster_csv_file = FCSV.new(datafile, :headers=>true, :return_headers=>true, :col_sep => separator)
        all_headers = faster_csv_file.shift
        headers = all_headers.headers
    #spreadsheet should already be converted
    else
	separator = ","
	faster_csv_file = FCSV.new(datafile, :headers=>true, :return_headers=>true, :col_sep => separator)
        all_headers = faster_csv_file.shift
        headers = all_headers.headers
    end
    
    headers.collect!{|item| item.strip}

    @new_variables = []
 
    headers.each do |var|
        variable = Variable.new
        variable.name = var
        variable.value = "No label"
        variable.dataset = dataset
        variable.updated_by = current_user.id
        variable.save
        @new_variables.push(variable.id)
    end
    expire_survey_cache
    begin 
      logger.info(Time.now.to_s + " processing dataset " + dataset.id.to_s + " user " + current_user.id.to_s + " and separator " + separator)
      Delayed::Job.enqueue ProcessDatasetJob::StartJobTask.new(dataset.id, current_user.id, separator, base_host)
    rescue Exception => e
      logger.error(Time.now.to_s + " " + e)
      raise e
    end
    
  end
  
  #Load a new CSV/Tabbed file for a survey.
  #Create the dataset and the variables from the header line
  def load_new_dataset filename
    datafile = File.open(filename, "r")
    @new_variables =[]
    #split by tab
    if params[:dataset_format] == "Tab Separated"
	separator = "\t"
	faster_csv_file = FCSV.new(datafile, :headers=>true, :return_headers=>true, :col_sep => separator)
        all_headers = faster_csv_file.shift
	headers = all_headers.headers
    #split by comma
    elsif params[:dataset_format] == "Comma Separated"
	separator = ","
	faster_csv_file = FCSV.new(datafile, :headers=>true, :return_headers=>true, :col_sep => separator)
        all_headers = faster_csv_file.shift
        headers = all_headers.headers
    #spreadsheet should already be converted
    else
	separator = ","
	faster_csv_file = FCSV.new(datafile, :headers=>true, :return_headers=>true, :col_sep => separator)
        all_headers = faster_csv_file.shift
        headers = all_headers.headers
    end
    
    headers.collect!{|item| item.strip}

    #need to find variables which are missing from the existing set and variables which are 'new'
    all_var = Variable.all(:conditions=> {:dataset_id => @dataset.id, :is_archived=>false}, :select => "name")

    all_variables = Array.new(all_var.size){|i| all_var[i].name}
    
   #expire any existing fragments
   all_var.each do |var|
	expire_action :action=>"surveys/collapse_row", :id=>var.id
	expire_action :action=>"surveys/expand_row", :id=>var.id
   end    

    missing_variables = all_variables - headers
    
    
    added_variables = headers - all_variables
    
    
    @missing_vars = []
    missing_variables.each do |missing_var|
      # grab the non archived vars in case the name is the same as a previous one
      v = Variable.find(:all,:conditions=> {:dataset_id=>@dataset.id, :name => missing_var, :is_archived => false})
      @missing_vars.push(v[0].id)
      v[0].update_attributes(:is_archived => true, :archived_by => current_user.id, :archived_on => Time.now)
      v[0].solr_destroy
    end
    
    @new_variables = []
 
    added_variables.each do |var|
        variable = Variable.new
        variable.name = var
        variable.value = "No label"
        variable.dataset = @dataset
        variable.updated_by = current_user.id
        variable.save
        @new_variables.push(variable.id)
    end

    #process the columns and get the stats - TODO - process only new columns?
    begin 
      Delayed::Job.enqueue ProcessDatasetJob::StartJobTask.new(@dataset.id, current_user.id, separator)
    rescue Exception => e
      logger.error(Time.now.to_s + " " + e)
      raise e
    end  
  end
  
  #if you own the parent survey or it is a ukda one and you are an admin
  def can_add_or_edit_datasets
    dataset = Dataset.find(params[:id])
    if !Authorization.is_authorized?("edit", nil, dataset.survey, current_user)
      if current_user && dataset.survey.survey_type.is_ukda && !current_user.is_admin?
        respond_to do |format|
          flash[:error] = "You do not have permission for this action"
          format.html { redirect_to dataset_url(dataset) }
        end
      end
    end
  end
  
  #if you own the parent survey or it is a ukda one and you are an admin
  def authorize_new
    if params[:survey]
      # /new?survey=X
      survey = Survey.find(params[:survey])
    else
      # post to /datasets ie create
       survey = Survey.find(params[:dataset][:survey])
    end
    if !Authorization.is_authorized?("edit", nil, survey, current_user) || current_user && survey.survey_type.is_ukda && !current_user.is_admin?
        respond_to do |format|
          flash[:error] = "You do not have permission for this action"
        format.html { redirect_to survey_url(survey) }
      end
    end
  end

  #check that the csv/tab datafile being uploaded is valid
  #before doing any sort of preprocessing 
  def check_datafile_ok filename
    datafile = File.open(filename, "r")
    @new_variables =[]

    #first check mime type
#TODO This will not work on windows since it depends on the unix tool file need to use a different way. Possible begin/rescue it so that
#failure does not matter
    mimetype = `file --mime -br #{datafile.path}`.gsub(/\n/,"").split(';')[0]
    #TODO not sure if this is really an exhaustive check, should get possible mimes from a list
    if mimetype.index("text") == nil && mimetype.index("csv") == nil && mimetype.index("office") == nil && mimetype.index("excel") == nil
#TODO This will not work on windows since it depends on the unix tool file need to use a different way. Possible begin/rescue it so that
#failure does not matter
      possible_mimetype = `file --mime -br #{datafile.path}`
      @datafile_error = "MethodBox cannot process this file.  Is it really a tab, csv or excel file? Checking the mime type revealed this: " + possible_mimetype
      return false
    end
    
    header =  datafile.readline
    #split by tab

    if params[:dataset_format] == "Tab Separated"
        headers = header.split("\t")
        separator = "\t"
    else
        headers = header.split(",")
        separator = ","
    end
    
    #check that there are no empty headers
    headers.collect!{|item| item.strip}
    headers.each do |header|
      if (header.match('([A-Za-z0-9]+)') == nil)
        datafile.close
        @datafile_error = "There are column headers with empty names or invalid characters"
        return false
      end
    end
    
    if headers.uniq! == nil
      datafile.close
      return true
    else
      datafile.close
      @datafile_error = "There are duplicate column headers.  Each column header must occur only once."
      return false
    end
    
  end

  def find_previous_searches
    search=[]
    if logged_in?
      search = UserSearch.all(:order => "created_at DESC", :limit => 5, :conditions => { :user_id => current_user.id})
    end
    @recent_searches = search
  end
  
end
