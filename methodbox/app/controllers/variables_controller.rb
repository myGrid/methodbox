class VariablesController < ApplicationController

  before_filter :login_required


  # GET /variable
  # GET /variable.xml
  def index

    if (!params[:variable].nil?)
      @tag = params[:variable]
      @variables = Variable.tagged_with(@tag, :on=>:title)
    else
      @variables = Variable.find(:all, :page=>{:size=>default_items_per_page,:current=>params[:page]}, :order=>:last_name)
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @variables.to_xml}
    end
    
  end
  
  def edit
    find_variable
    @all_tags = @variable.title_counts
  end

  def update
    find_variable
    respond_to do |format|
      format.html { redirect_to variable_path(@variable) }
    end
  end

  def watch
    puts "watching or stop"
    find_variable
    if !Person.find(current_user.id).watched_variables.any?{|var| var.variable_id == @variable.id}
      #      user wants to watch a variable
      puts "watching " + @variable.id.to_s
      person = Person.find(current_user.person_id)
      person.watched_variables.create(:variable_id => @variable.id)
    else
      #      stop watching variable
      puts "stop watching " + @variable.id.to_s
      person = Person.find(current_user.person_id)
      watched = person.watched_variables.find(:all, :conditions => "variable_id=" + @variable.id.to_s)
      WatchedVariable.delete(watched)
    end
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
