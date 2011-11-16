class DataProvidersController < ApplicationController
  
  def index
    @data_providers = DataProvider.all
  end
  
  def download
  end
  
end