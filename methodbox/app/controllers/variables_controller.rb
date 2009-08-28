class VariablesController < ApplicationController

  before_filter :login_required

  def edit
    find_variable
    @all_tags = @variable.title_counts
  end

  def update
    respond_to do |format|
      format.html { redirect_to variable_path(@variable) }
    end
  end

  def show
    find_variable
    #    @tag_array = Array.new
    #    @variable.annotations_with_attribute("tag").each do |annotation|
    #
    #      tag = Tag.new
    #      tag.id = annotation.id
    #      tag.name = annotation.value
    #      @tag_array.push(tag)
    #
    #    end
    @tag_array = @variable.title_counts
  end
  
  def save_tags
    
  end

  def find_variable
    @variable = Variable.find(params[:id])
  end

  def search_for_tags
    find_variable
    @tag = Tag.find(params[:tag_id])
    puts "search_for_tags " + params[:id]
    render :update, :status=>:created do |page|
    page.replace_html "tag_search", :partial=>"variables/search_for_tags"
  end
  end

end
