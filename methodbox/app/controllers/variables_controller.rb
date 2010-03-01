class VariablesController < ApplicationController

  before_filter :login_required

  def open_pdf
    find_variable
    type = Survey.find(Dataset.find(@variable.dataset_id).survey_id).surveytype.downcase
    year = Survey.find(Dataset.find(@variable.dataset_id).survey_id).year
    send_file(RAILS_ROOT + "/" + "filestore" + "/docs" + "/" + type + "/" + year + "/" + @variable.document + "#page=" + @variable.page, :type => 'application/pdf', :disposition => 'inline')
  end

  def by_category
    @category = params[:category]
    @sorted_variables = Variable.find(:all, :conditions=>"category='" + params[:category] + "'")
  end

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

  def add_to_cart
    find_variable

    session[:cart].add_variable(@variable.id)

    respond_to do |format|
      flash[:notice] = "Variable has been added to the cart"
      format.html { redirect_to variable_path(@variable) }
    end

  end

  def add_multiple_to_cart
    @variable_list = Array.new(params[:variable_ids])

    @variable_list.each do |var|
      variable = Variable.find(var)
      session[:cart].add_variable(variable.id)
    end

    render :update, :status=>:created do |page|
      #        TODO flash the cart
      #                page[:cart_button].reload
      page.replace_html "cart_button", :partial=>"surveys/cart_button"
      page[:cart_button].visual_effect(:pulsate, :duration=>2.seconds)
      #                page.visual_effect :highlight, 'cart_button' ,:duration => 1
      #        page.replace_html "cart-total", :partial=>"surveys/cart_total"
    end

  end

  def update
    find_variable
    
    curr_tags = @variable.title_list

    @all_tags_array = Array.new
    param = @variable.name+ @variable.survey_id.to_s + '_variable_autocompleter_unrecognized_items'
    #      param2 = varname +surveyyear +'_variable_autocompleter_selected_ids'
    taghash = params[param]
    #      oldtaghash = params[param2]
    #      if oldtaghash != nil
    #        oldtaghash.each do |oldtag|
    #          @all_tags_array.push(Tag.find(oldtag).name)
    #        end
      

    if taghash != nil
      if !taghash.empty?
          
        taghash.each do |tag|
          @all_tags_array.push(tag.to_s)
          #            data = {"tag"=>[tag.to_s]}
          #            variable = Variable.find(varid)
          #            variable.create_annotations(data,person)
          puts "new tag: " + tag
        end
          
        
          
      end
      
    end
      
    # cope with new tags that have been added by clicking on the suggestions box

    param1 = @variable.name+ @variable.survey_id.to_s + '_variable_autocompleter_selected_ids'
    taghash2 = params[param1]
      

    if taghash2 != nil
      if !taghash2.empty?
          
        taghash2.each do |tag|
          ntag = Tag.find(tag)
          @all_tags_array.push(ntag.name)
          #            data = {"tag"=>[tag.to_s]}
          #            variable = Variable.find(varid)
          #            variable.create_annotations(data,person)
          puts "new tag: " + tag
        end
          
        
          
      end
      
    end

    str = ""
    #        puts "curr user " + current_user.id.to_s
    #        person = Person.find(current_user.id)
    @all_tags_array.each do |newtag|
      str =str + newtag +","
    end
    curr_tags = @variable.title_list
    curr_tags.each do |tag|
      str = str + tag + ","
    end

    puts "tagged with " + str
    @variable.title_list = str
    @variable.save_tags
    
    
    
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
