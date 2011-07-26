class VariablesController < ApplicationController

  before_filter :login_required, :except => [ :help, :open_pdf, :by_category, :show, :find_for_multiple_surveys_by_category]
  before_filter :is_user_admin_auth, :only =>[ :deprecate_variable, :edit, :update, :create]
  after_filter :update_last_user_activity
  before_filter :find_comments, :only=>[ :show ]
  before_filter :find_notes, :only=>[ :show ]

  #caches_page :show
  
  #a users private notes about a variable
  def add_note
    @variable = Variable.find(params[:resource_id])
    note = Note.new(:words=>params[:words], :user_id=>current_user.id, :notable_id=>@variable.id, :notable_type=>"Variable")
    note.save
    render :partial=>"notes/note", :locals=>{:note=>note}
  end
  
  #add a user owned comment to a variable and add it to the view
  def add_comment
    @variable = Variable.find(params[:resource_id])
    comment = Comment.new(:words=>params[:words], :user_id=>current_user.id, :commentable_id=>@variable.id, :commentable_type=>"Variable")
    comment.save
    render :partial=>"comments/comment", :locals=>{:comment=>comment}
  end

  def find_for_multiple_surveys_by_category
    if params[:survey_ids]
    @sorted_variables = []
    @category = params[:category]
    params[:survey_ids].each do |survey_id|
      survey = Survey.find(survey_id)
      survey.datasets.each do |dataset|
        @sorted_variables.concat(Variable.all(:conditions=>({:category => params[:category], :dataset_id => dataset.id})))      
      end
    end
    render :update, :status=>:created do |page|
      page.replace_html "variables_list", :partial => "variables_by_category"
    end
  else
    render :update, :status=>:created do |page|
    page.replace_html "variables_list", "<b style='color: red; font-size: 130%; font-style: italic;'>Please select some surveys first and then click on a category</b>"
  end
  end
  end
  
  def deprecate
    find_variable
    deleted_id = @variable.id
    @variable.replaced_by = params[:replaces].to_i
    @variable.solr_destroy
    @variable.archived_by = current_user.id
    @variable.archived_reason = params[:reason]
    @variable.is_archived = true
    @variable.save
    
    render :update, :status=>:created do |page|
      page.replace_html "#{deleted_id}", :partial=>"datasets/archived_variable"
    end
    
  end

  def open_pdf
    find_variable
    #TODO: the survey type shortname is only relevant to HSE/GHS, at some point may want to phase it out
    #completely
    type = Survey.find(Dataset.find(@variable.dataset_id).survey_id).survey_type.shortname.downcase
    year = Survey.find(Dataset.find(@variable.dataset_id).survey_id).year
    send_file(RAILS_ROOT + "/" + "filestore" + "/docs" + "/" + type + "/" + year + "/" + @variable.document, :type => 'application/pdf', :disposition => 'inline')
  end

  def by_category
    @sorted_variables = []
    @category = params[:category]
    if params[:survey]
      survey_id = params[:survey]
      survey = Survey.find(survey_id)
      survey.datasets.each do |dataset|
        @sorted_variables.concat(Variable.all(:conditions=>({:category => params[:category], :dataset_id => dataset.id})))      
      end
      @sorted_variables.uniq!
      @title = "Variables from " + survey.title
    else
      @sorted_variables = Variable.all(:conditions=>({:category=> params[:category]}))
      @title = "All variables"
    end
  end

  def index
    @variables = Variable.all(:page=>{:size=>default_items_per_page,:current=>params[:page]}, :order=>:name)

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


    if CartItem.find_by_user_id_and_variable_id(current_user,@variable)
    else
      an_item = CartItem.new
      an_item.user = current_user
      an_item.variable = @variable
      an_item.save
      current_user.reload
    end

    respond_to do |format|
      flash[:notice] = "Variable has been added to the cart"
      format.html { redirect_to variable_path(@variable) }
    end

  end

  def add_multiple_to_cart
    @variable_list = Array.new(params[:variable_ids])
    @variable_list.each do |var|
      if CartItem.find_by_user_id_and_variable_id(current_user,var)
        puts "User already has variable "+var.to_s
      else
        an_item = CartItem.new
        an_item.user = current_user
        an_item.variable_id = var
        an_item.save
        current_user.reload
      end
    end

    render :update, :status=>:created do |page|
      #        TODO flash the cart
      #                page[:cart_button].reload
      page.replace_html "cart_button", :partial=>"cart/button"
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
    taghash = params[param]


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

    @variable.title_list = str
    @variable.save_tags

    #expire_page :action=>"show", :id=>@variable.id

    respond_to do |format|
      format.html { redirect_to variable_path(@variable) }
    end
  end

  def watch
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

  # Find the correct variable, any tags associated with it and variables
  # which are matched in data extracts with it
  def show
    find_variable
    if authorized_to_see @variable
    @value_domain_hash = Hash.new
    @var_hash = Hash.new
    @no_var_hash = Hash.new
    @blank_rows = nil
    @invalid_entries = nil
    @total_entries = nil
    @valid_entries = nil
    if @variable.nesstar_id
      @variable.value_domains.each do |value_domain|
        if value_domain.value_domain_statistic
	  @var_hash[value_domain.id] = value_domain.value_domain_statistic.frequency
	end
	  @value_domain_hash[value_domain.id] = value_domain.label
      end
        @valid_entries = @variable.valid_entries
        @invalid_entries = @variable.invalid_entries

      if @valid_entries == nil
        @total_entries = @invalid_entries
      elsif @invalid_entries == nil
        @total_entries = @valid_entries
      else
        @total_entries = @invalid_entries + @valid_entries
      end
    else
      @no_var_hash = @variable.none_values_hash
      @var_hash = @variable.values_hash
      @value_domain_hash = Hash.new
      @var_hash.each_key do |key|
        @variable.value_domains.each do |value_domain|
	  if value_domain.value.to_i.eql?(key.to_i)
	    @value_domain_hash[key] = value_domain.label
	    break
	  end
	end
      end
      @blank_rows = @variable.number_of_blank_rows
      @invalid_entries = 0
      @no_var_hash.each_key do |key|
        @variable.value_domains.each do |value_domain|
	  if value_domain.value.to_i.eql?(key.to_i)
	    @value_domain_hash[key] = value_domain.label
	    break
	  else
	    @value_domain_hash[key] = key
	  end
	end
	@invalid_entries += @no_var_hash[key]
      end
      @valid_entries = 0
      @var_hash.each_key do |key|
        @valid_entries += @var_hash[key]
      end
      @no_var_hash.each_key do |key|
        @valid_entries += @var_hash[key]
      end
       if @valid_entries == nil
         @total_entries = @invalid_entries
       elsif @invalid_entries == nil
        @total_entries = @valid_entries
       else
         @total_entries = @invalid_entries + @valid_entries
       end
      if @blank_rows != nil
        @total_entries += @blank_rows
      end
#If there are no values then see if the value domains have any frequency stats - relevant to vars from nesstar ddi datasets
      if @var_hash.empty?
        @variable.value_domains.each do |value_domain|
	  if value_domain.value_domain_statistic
	    if value_domain.value_domain_statistic
	      @var_hash[value_domain.value] = value_domain.value_domain_statistic.frequency
	    end
	    @value_domain_hash[value_domain.value] = value_domain.label
	  end
	end
      end
    end
    @tag_array = @variable.title_counts
    #find the variables which occur in data extracts for this variable
    @sorted_matches = []
    matches = MatchedVariable.all(:conditions => {:variable_id => @variable.id}, :order => "occurences DESC", :limit => 6)
    if !matches.empty?
      @sorted_matches = matches
    end
    
  else
    respond_to do |format|
      flash[:error] = "You are not authorized to view this variable"
      format.html {redirect_to back}
    end
  end
    
  end

  def save_tags

  end

  def find_variable
    @variable = Variable.find(params[:id])
  end

  def search_for_tags
    find_variable
    @tag = Tag.find(params[:tag_id])
    render :update, :status=>:created do |page|
      page.replace_html "tag_search", :partial=>"variables/search_for_tags"
    end
  end
  
  def find_comments
    @variable =Variable.find(params[:id])
    @comments = @variable.comments
  end
  
  def find_notes
    if current_user
      @variable =Variable.find(params[:id])
      @notes = Note.all(:conditions=>{:notable_type => "Variable", :user_id=>current_user.id, :notable_id => @variable.id})
    end
  end
  
  def authorized_to_see variable
    Authorization.is_authorized?("show", nil, variable.dataset.survey, current_user)
  end

end
