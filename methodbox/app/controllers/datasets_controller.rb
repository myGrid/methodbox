class DatasetsController < ApplicationController

  before_filter :login_required, :except => [ :show ]
  before_filter :find_datasets, :only => [ :index ]
  before_filter :find_dataset, :only => [ :show, :edit ]

  def index

  end

  def show
    
  end
  
  def edit
    flash[:error] = "No dataset editing is allowed at the moment"
    respond_to do |format|
      format.html { redirect_to dataset_path(@dataset) }
    end
  end

  private

  def find_dataset
    @dataset = Dataset.find(params[:id])
  end

  def find_datasets
    @datasets = Dataset.find(params[:all])
  end
  
end