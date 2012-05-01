class VariableLinksController < ApplicationController
  before_filter :authenticate_user!, :find_link

  def show

  end
  
  def find_link
    @link = VariableLink.find(params[:id])
  end

end
