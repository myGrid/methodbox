class CartController < ApplicationController

  before_filter :authenticate_user!
  after_filter :update_last_user_activity
  #  before_filter :find_archives, :only => [ :index ]

  def add_to_cart
    #if params[:extract_id]
    #  extract_id_for_items = params[:extract_id]
    #end
    #if params[:search_terms]
    #  search_terms = Array.new(params[:search_terms])
    #  search_term_tracker = params[:search_term_tracker]
    #end
    #if params[:from_a_previous_search]
    #  previous_search_id = params[:from_a_previous_search]
    #end


#    case params[:value]
#    when "add"
      @variable_list = Array.new(params[:variable_ids])

      @variable_list.each do |var|
        #search_term_for_var = String.new
        #if search_terms
        #  search_terms.each do |term|
        #    if search_term_tracker.has_key?(term)
        #      search_term_tracker[term].each do |search_term_hash|
        #        search_term_hash.each do |term_var|
        #          if (term_var == var)
        #            search_term_for_var = term
        #            break
        #          end
        #        end
        #      end
        #    end
        #  end
#        elsif params[:survey_search_query]
#            search_term_for_var = params[:survey_search_query]
        #end
        
       if CartItem.find_by_user_id_and_variable_id(current_user,var)
         
       else
	 an_item = CartItem.new
         an_item.user = current_user
         an_item.variable_id = var
         #if extract_id_for_items
         #  an_item.extract_id = extract_id_for_items
         #end
         #if previous_search_id
         #  an_item.user_search_id = previous_search_id
         #end
         #an_item.search_term = search_term_for_var
         an_item.save
         current_user.reload
       end
      end

      #render :update, :status=>:created do |page|
      #  page.replace_html "cart-buttons", :partial=>"cart/all_buttons"
      #  #page.replace_html "create-data-extract-button", :partial=>"surveys/create_extract_button"
      #  page[:cart_button].visual_effect(:pulsate, :duration=>2)
      #end
    respond_to do |format|
      format.html # index.html.erb
      #format.xml 
      format.js
    end
#    end
  end

  def show
    missing_vars=[]
    @archived_vars=[]
    @sorted_variables = Array.new
    @target_matches = Hash.new
    
    #array with the var id from the current cart
    current_cart = current_user.cart_items.collect {|item| item.variable_id}
    
    current_user.cart_items.each do |item|
      begin
        var = Variable.find(item.variable_id)
        if var.is_archived?
          @archived_vars.push(item)
        else
          @sorted_variables.push(var)
        end
        
      rescue ActiveRecord::RecordNotFound
        missing_vars.push(item.variable_id)
        current_user.cart_items.delete(item)
      end
    end
    @archived_vars.each do |var|
      current_user.cart_items.delete(var)
    end
    if !missing_vars.empty?
      flash[:notice] = "Your cart contained some variables which no longer exist. They have been removed from your cart."
    end
    @sorted_matches = Hash.new
    #find the variables which occur in data extracts for each variable in the cart
    @sorted_variables.each do |var|     
      matches = MatchedVariable.all(:conditions => {:variable_id => var.id}, :order => "occurences DESC", :limit => 3)
      matches.each do |match|
        if @target_matches.has_key?(match.target_variable_id)
          @target_matches[match.target_variable_id] += match.occurences 
        else
          @target_matches[match.target_variable_id] = match.occurences 
        end
      end
    end
    @target_matches.delete_if{|key,value| current_cart.include?(key)}
    @target_matches.sort{|a,b| b[1]<=>a[1]}
    variables_hash = {"total_entries"=>@sorted_variables.size, "results" => @sorted_variables.sort{|x,y| x.name <=> y.name}.collect{|variable| {"id" => variable.id, "name"=> variable.name, "description"=>variable.value, "dataset"=>variable.dataset.name, "dataset_id"=>variable.dataset.id.to_s, "survey"=>variable.dataset.survey.title, "survey_id"=>variable.dataset.survey.id.to_s, "year" => variable.dataset.survey.year, "category"=>variable.category, "popularity" => VariableList.all(:conditions=>"variable_id=" + variable.id.to_s).size}}}
    @variables_json = variables_hash.to_json
  end

  def remove_from_cart
    @var_list = params[:variable_ids]
    unless @var_list.empty?
      @var_list.each do |var|
        item = CartItem.find_by_user_id_and_variable_id(current_user,var)
        if item
          item.destroy
        end  
      end
      current_user.reload
    end
    @target_matches = Hash.new
    @sorted_variables = Array.new
    current_user.cart_items.each do |item|
      var = Variable.find(item.variable_id)
      @sorted_variables.push(var)
    end
    #array with the var id from the current cart
    current_cart = current_user.cart_items.collect {|item| item.variable_id}
    
    @sorted_matches = Hash.new
    #find the variables which occur in data extracts for each variable in the cart
    @sorted_variables.each do |var|     
      matches = MatchedVariable.all(:conditions => {:variable_id => var.id}, :order => "occurences DESC", :limit => 3)
      matches.each do |match|
        if @target_matches.has_key?(match.target_variable_id)
          @target_matches[match.target_variable_id] += match.occurences 
        else
          @target_matches[match.target_variable_id] = match.occurences 
        end
      end
    end
    @target_matches.delete_if{|key,value| current_cart.include?(key)}
    @target_matches.sort{|a,b| b[1]<=>a[1]}
    variables_hash = {"total_entries"=>@sorted_variables.size, "results" => @sorted_variables.sort{|x,y| x.name <=> y.name}.collect{|variable| {"id" => variable.id, "name"=> variable.name, "description"=>variable.value, "survey"=>variable.dataset.survey.title, "year" => variable.dataset.survey.year, "category"=>variable.category, "popularity" => VariableList.all(:conditions=>"variable_id=" + variable.id.to_s).size}}}
    @variables_json = variables_hash.to_json
    if current_user.cart_items.empty?
      render :update do |page|
        page.redirect_to(:controller => "surveys", :action => "index")
        page << "alert('You have no variables left in your cart.  To create a new Data Extract you need to search for some and add to your cart.');"    
      end
    else
      render :update do |page|
        #refresh the var table with the remaining variables
        page << "updateTable('#{@variables_json}');"
        page.replace_html "cart-buttons", :partial=>"cart/all_buttons"
        page[:cart_button].visual_effect(:pulsate, :duration=>2)
      end
    end
  end

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml 
    end
  end

end
