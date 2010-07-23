class DatasetsController < ApplicationController

  before_filter :is_user_admin_auth, :only =>[ :new, :create, :edit]
  before_filter :login_required, :except => [ :show ]
  before_filter :find_datasets, :only => [ :index ]
  before_filter :find_dataset, :only => [ :show, :edit, :update ]

  def index

  end

  def show
    
  end
  
  def new
    @survey = Survey.find(params[:survey])
  end
  
  def create
    load_new_dataset 
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
    if (params[:file][:metadata] rescue nil)
      case params[:dataset_metadata_format]
      when "CCSR"
        read_ccsr_metadata
      end
    end
    
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
  
  def update_metadata
        puts "stuff happening here"
        puts params[:dataset][:metadata].class
  end

  private

  def find_dataset
    @dataset = Dataset.find(params[:id])
  end

  def find_datasets
    @datasets = Dataset.find(params[:all])
  end
  
  private
  
  #new - not tested via ui yet
  #Load a new CSV/Tabbed file for a survey.
  #Create the dataset and the variables from the header line
  def load_new_dataset
    dataset = Dataset.new
    dataset.survey = Survey.find(params[:dataset][:survey])
    dataset.name = params[:dataset][:title]
    dataset.description = params[:dataset][:description]
    dataset.filename = params[:dataset][:data].original_filename
    dataset.save
    @dataset = dataset
    header =  params[:dataset][:data].readline
    #split by tab
    if params[:dataset_format] == "Tab Separated"
        headers = header.split("\t")
    else
        headers = header.split(",")
    end
 
    headers.each do |var|
      variable = Variable.new
      variable.name = var
      variable.dataset = dataset
      variable.save
    end
    
    #TODO - push the file over to the CSV server (or just copy it to a directory somewhere?!?)
    
  end
  
  #new - not tested via ui yet
  #Read the metadata from a ccsr type xml file for a particular survey
  def read_ccsr_metadata
    # puts params[:dataset][:metadata].class
    # data = params[:dataset][:metadata].read
    parser = XML::Parser.io(params[:file][:metadata], :encoding => XML::Encoding::ISO_8859_1)
    doc = parser.parse

      nodes = doc.find('//ccsrmetadata/variables')
      # doc.close

      nodes[0].each_element do |node|
        if (/^id_/.match(node.name)) 
          name = node["variable_name"]
          label = node["variable_label"]
          puts name + " " + label
          value_map = String.new
          node.each_element do |child_node| 
            if (!child_node.empty?) 
              value_map <<  "value " + child_node["value"] + " label " + child_node["value_name"] + "\r\n"
            end
            puts value_map
          end
        #TODO get the variable using active record and fill in the blanks
        #if there are no variables for the dataset already then we should flag that up
          variable = Variable.new
                   # variable.name = name
                   # variable.value= label
          #          variable.dertype = variable_dertype
          #          variable.dermethod = variable_dermethod
                   # variable.info = value_map
          #          variable.category = variable_category
                   # variable.dataset = @dataset
          #          variable.page = page
          #          variable.document = document
                   # variable.save
          end
        end
        
  end
  
end