require 'rest_client'
require 'uuidtools'

class DatasetsController < ApplicationController

  include ProcessDatasetJob

  # before_filter :is_user_admin_auth, :only =>[ :new, :create, :edit, :update, :update_data, :update_metadata, :load_new_data, :load_new_metadata]
  before_filter :authorize_new, :only => [ :new, :create ]
  before_filter :login_required, :except => [ :show ]
  before_filter :find_datasets, :only => [ :index ]
  before_filter :find_dataset, :only => [ :show, :edit, :update, :update_data, :update_metadata, :load_new_data, :load_new_metadata ]
  before_filter :can_add_or_edit_datasets, :only => [ :edit, :load_new_data, :load_new_metadata, :update ]
  after_filter :update_last_user_activity
  
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
      params[:file][:data].each_line do |line|                
        uf.write(line)
      end
      uf.close
    
      if check_datafile_ok filename
        @dataset.update_attributes(:reason_for_update=>params[:update][:reason], :updated_by=>current_user.id, :filename=>params[:file][:data].original_filename, :uuid_filename=> uuid + ".data", :current_version => new_dataset_version, :has_data=>true)
        load_new_dataset filename
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
      logger.error(e)
      @dataset.update_attributes(:reason_for_update=>old_reason_for_update, :updated_by=>old_updated_by, :filename=>old_filename, :uuid_filename=> old_uuid_filename, :current_version => old_current_version,:has_data=>old_has_data)
      respond_to do |format|
        flash[:error] = "There was a problem updating the dataset. Please try again. The error was: " + e
        format.html { redirect_to dataset_path(@dataset) }
      end
    end
  end
  
  #update the metadata for this dataset
  def load_new_metadata
    if @dataset.filename != nil
    case params[:dataset_metadata_format]
    when "CCSR"
      read_ccsr_metadata
    when "Methodbox"
      read_methodbox_metadata
    end
    @dataset.update_attributes(:has_variables=>true)
    respond_to do |format|
      flash[:notice] = "The metadata has been updated."  
      format.html { redirect_to dataset_path(@dataset) }
    end
  else
    respond_to do |format|
      flash[:error] = "There are no variables in this dataset.  Please upload a dataset"
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
      filename=CSV_FILE_PATH + "/" + uuid + ".data"
      uf = File.open(filename,"w")
      params[:dataset][:data].each_line do |line|                
        uf.write(line)
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
        dataset.update_attributes(:has_variables=>false)
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
      logger.error(e)
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
        logger.info("this was new " + variable.name)
        @new_variables.push(variable)
      end
    end
  end
  
  #Load the first CSV/Tabbed file for a survey.
  #Create the variables from the header line
  def load_dataset filename, dataset
    datafile = File.open(filename, "r")
    @new_variables =[]
    header =  datafile.readline
    #split by tab
    if params[:dataset_format] == "Tab Separated"
        headers = header.split("\t")
        separator = "\t"
    else
        headers = header.split(",")
        separator = ","
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
    
    begin 
      logger.info("sending the job with dataset " + dataset.id.to_s + " user " + current_user.id.to_s + " and separator " + separator)
      Delayed::Job.enqueue ProcessDatasetJob::StartJobTask.new(dataset.id, current_user.id, separator, base_host)
    rescue Exception => e
      logger.error(e)
      raise e
    end
    
  end
  
  #Load a new CSV/Tabbed file for a survey.
  #Create the dataset and the variables from the header line
  def load_new_dataset filename
    datafile = File.open(filename, "r")
    @new_variables =[]
    header =  datafile.readline
    #split by tab

    if params[:dataset_format] == "Tab Separated"
        headers = header.split("\t")
        separator = "\t"
    else
        headers = header.split(",")
        separator = ","
    end
    
    headers.collect!{|item| item.strip}

    #need to find variables which are missing from the existing set and variables which are 'new'
    all_var = Variable.all(:conditions=> {:dataset_id => @dataset.id, :is_archived=>false}, :select => "name")

    all_variables = Array.new(all_var.size){|i| all_var[i].name}
    
    
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
      logger.error(e)
      raise e
    end  
  end
  
  #Read the metadata from a methodbox internal formatted xml file for a particular survey
  def read_methodbox_metadata
    #don't think we need encoding here
    parser = XML::Parser.io(params[:file][:metadata])
    doc = parser.parse
    
    nodes = doc.find('//metadata/variable')

    nodes.each do |node|
    
      namenode = node.find('child::name')
      namecontent = namenode.first.content
              print " NAME: " + namecontent

      variable_name = namecontent

      descnode = node.find('child::description')
      desccontent = descnode.first.content
              print " DESC: " + desccontent
      variable_value = desccontent
    
      catnode = node.find('child::category')
      catcontent = catnode.first.content
              print " CAT: " + catcontent
      variable_category = catcontent
      
      dernode = node.find('child::derivation')
      dercontent = dernode.first
    
      dertype = dercontent.find('child::type')
      if dertype.first != nil
        dertypecontent = dertype.first.content
        variable_dertype = dertypecontent
                  print " TYPE: " + dertypecontent
      else
                  print "TYPE: NIL"
      end
    
      dermethod = dercontent.find('child::method')
      if dermethod.first != nil
        dermethodcontent = dermethod.first.content
        variable_dermethod = dermethodcontent

        page = dermethod[0].[]("page")

        document = dermethod[0].[]("document")

                  print "METHOD: " + dermethodcontent
        if page != nil
                       print " page: " + page + " document: " + document
        end
      else
                  print "METHOD: NIL"
      end
      
      infonode = node.find('child::information')
      infocontent = infonode.first.content
      variable_info = infocontent
      print "INFO: " + infocontent
      v = Variable.find(:all,:conditions=> {:dataset_id => @dataset.id, :is_archived=>false, :name=>variable_name})
      if (v[0]!= nil)
        v[0].update_attributes(:value=>variable_value, :dertype=>variable_dertype, :dermethod=>variable_dermethod, :info=>variable_info,:category=>variable_category, :page=>page, :document=>document, :update_reason=>params[:update][:reason])
        
        end
      end
  end
  
  #Read the metadata from a ccsr type xml file for a particular survey
  def read_ccsr_metadata

    @missing_variables=[]
    parser = XML::Parser.io(params[:file][:metadata], :encoding => XML::Encoding::ISO_8859_1)
    doc = parser.parse

      nodes = doc.find('//ccsrmetadata/variables')
      if nodes.size == 1
      nodes[0].each_element do |node|
        if (/^id_/.match(node.name)) 
          name = node["variable_name"]
          label = node["variable_label"]
          v = Variable.find(:all,:conditions=> {:dataset_id => @dataset.id, :is_archived=>false, :name=>name})
          if (v[0]!= nil)
            v[0].value_domains.each do |valdom|
              valdom.delete
            end
          value_map = String.new
          node.each_element do |child_node| 
            if (!child_node.empty?) 
              valDom = ValueDomain.new
              valDom.variable = v[0]
              valDom.label = child_node["value_name"]
              valDom.value = child_node["value"]
              value_map <<  "value " + child_node["value"] + " label " + child_node["value_name"] + "\r\n"
              valDom.save
            end
        end
          v[0].update_attributes(:value=>label, :info=>value_map,:updated_by=>current_user.id, :update_reason=>params[:update][:reason])
          
        # don't care about 'false positives' in the metadata, all we care about is the columns from the original dataset
        end
      end  
  end
else
      nodes.each do |node|
          name = node["variable_name"]
          label = node["variable_label"]
          v = Variable.find(:all,:conditions=> {:dataset_id => @dataset.id, :is_archived=>false, :name=>name})
          if (v[0]!= nil)
            v[0].value_domains.each do |valdom|
              valdom.delete
            end
          value_map = String.new
          node.each_element do |child_node| 
            if (!child_node.empty?) 
              valDom = ValueDomain.new
              valDom.variable = v[0]
              valDom.label = child_node["value_name"]
              valDom.value = child_node["value"]
              value_map <<  "value " + child_node["value"] + " label " + child_node["value_name"] + "\r\n"
              valDom.save
            end
        end

          v[0].update_attributes(:value=>label, :info=>value_map,:updated_by=>current_user.id, :update_reason=>params[:update][:reason])
          
        # don't care about 'false positives' in the metadata, all we care about is the columns from the original dataset
        end 
  end
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
    if !Authorization.is_authorized?("edit", nil, survey, current_user) || current_user && survey.survey_type.is_ukda && current_user.is_admin?
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
    mimetype = `file --mime -br #{datafile.path}`.gsub(/\n/,"").split(';')[0]
    if mimetype.index("text") == nil && mimetype.index("csv") == nil
      possible_mimetype = `file -b #{datafile.path}`
      @datafile_error = "MethodBox cannot process this file.  Is it really a tab or csv file? Checking the mime type revealed this: " + possible_mimetype
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
  
end