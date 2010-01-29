class VariableLinksController < ApplicationController
  before_filter :login_required, :find_link

  def show

  end
  
  def find_link
    @link = VariableLink.find(params[:id])
  end

end
