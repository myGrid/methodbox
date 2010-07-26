class DatasetsController < ApplicationController

  before_filter :is_user_admin_auth, :only =>[ :new, :create, :edit]
  before_filter :login_required, :except => [ :show ]
  before_filter :find_datasets, :only => [ :index ]
  before_filter :find_dataset, :only => [ :show, :edit, :update, :update_data, :update_metadata, :load_new_data, :load_new_metadata ]
  
  def load_new_data
    load_new_dataset 
    respond_to do |format|
      format.html { redirect_to dataset_path(@dataset) }
    end
  end
  
  def load_new_metadata
    case params[:dataset_metadata_format]
    when "CCSR"
      read_ccsr_metadata
    end
    respond_to do |format|
      flash[:notice] = "The metadata has been updated."  
      format.html { redirect_to dataset_path(@dataset) }
    end
  end
  
  def update_data

  end
  
  def update_metadata
    case params[:dataset_metadata_format]
    when "CCSR"
      read_ccsr_metadata
    end
    respond_to do |format|
      flash[:notice] = "The metadata has been updated."  
      format.html { redirect_to dataset_path(@dataset) }
    end
  end

  def index

  end

  def show
    
  end
  
  def new
    @survey = Survey.find(params[:survey])
  end
  
  def create
    dataset = Dataset.new
    dataset.survey = Survey.find(params[:dataset][:survey])
    dataset.name = params[:dataset][:title]
    dataset.description = params[:dataset][:description]
    dataset.filename = params[:dataset][:data].original_filename
    dataset.save
    @dataset = dataset
    respond_to do |format|
      format.html { redirect_to dataset_path(@dataset) }
    end
    
  end
  
  def edit
    # flash[:error] = "No dataset editing is allowed at the moment"
    # respond_to do |format|
    #   format.html { redirect_to dataset_path(@dataset) }
    # end
  end
  
  def update
    #not sure if this is really the way to check for nil param but
    #everything else threw an error about NoMethodError (undefined method `[]' for nil:NilClass):
    # if (params[:file][:data] rescue nil)
    #       
    #     else
    #       update_dataset
    #     end
    #     if (params[:file][:metadata] rescue nil)
    #       case params[:dataset_metadata_format]
    #       when "CCSR"
    #         read_ccsr_metadata
    #       end
    #     end
    
    if @dataset.update_attributes(params[:dataset])
      respond_to do |format|
        # if @missing_variables.size >= 1
        #           flash[:notice] = "Variables were found in the metadata which had not previously been found in the uploaded CSV dataset.  It is recommended that you upload a new dataset which contains these variables and then reload the metadata"  
        #         end
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
    @datasets = Dataset.find(params[:all])
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
    #need to find variables which are missing from the exisitng set and variables which are 'new'
    all_var = Variable.all(:conditions=> "dataset_id=" + @dataset.id.to_s, :select => "name")

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
        variable.dataset = dataset
        variable.save
        puts "this was new " + variable.name
        @new_variables.push(variable)
      end
    end
    @new_variables.each {|new_variable| puts new_variable.name}
  end
  
  #new - not tested via ui yet
  #Load a new CSV/Tabbed file for a survey.
  #Create the dataset and the variables from the header line
  def load_new_dataset
    @new_variables =[]
    header =  params[:file][:data].readline
    #split by tab
    if params[:dataset_format] == "Tab Separated"
        headers = header.split("\t")
    else
        headers = header.split(",")
    end
    
    #need to find variables which are missing from the exisitng set and variables which are 'new'
    all_var = Variable.all(:conditions=> "dataset_id=" + @dataset.id.to_s, :select => "name")

    all_variables = Array.new(all_var.size){|i| all_var[i].name}
    
    missing_variables = all_variables - headers
    
    added_variables = headers - all_variables
    
    @missing_vars = []
    missing_variables.each do |missing_var|
      v = Variable.find(:all,:conditions=> "dataset_id=" + @dataset.id.to_s + " and name='" + missing_var+"'")
      @missing_vars.push(v.id)
    end
    
    @new_variables = []
 
    added_variables.each do |var|
        variable = Variable.new
        variable.name = var
        variable.dataset = @dataset
        variable.save
        @new_variables.push(var.id)
    end
    
    #TODO - push the file over to the CSV server (or just copy it to a directory somewhere?!?)
    
  end
  
  #new - not tested via ui yet
  #Read the metadata from a ccsr type xml file for a particular survey
  def read_ccsr_metadata
    # puts params[:dataset][:metadata].class
    # data = params[:dataset][:metadata].read
    @missing_variables=[]
    parser = XML::Parser.io(params[:file][:metadata], :encoding => XML::Encoding::ISO_8859_1)
    doc = parser.parse

      nodes = doc.find('//ccsrmetadata/variables')
      # doc.close

      nodes[0].each_element do |node|
        if (/^id_/.match(node.name)) 
          name = node["variable_name"]
          label = node["variable_label"]
          # puts name + " " + label
          value_map = String.new
          node.each_element do |child_node| 
            if (!child_node.empty?) 
              value_map <<  "value " + child_node["value"] + " label " + child_node["value_name"] + "\r\n"
            end
            # puts value_map
          end
        v = Variable.find(:all,:conditions=> "dataset_id=" + @dataset.id.to_s + " and name='" + name+"'")
        if (v[0]!= nil)
          v[0].update_attributes(:value=>label, :info=>value_map)
          
        # don't care about 'false positives' in the metadata, all we care about is the columns from the original dataset
        end
        end
        
  end
end
  
end