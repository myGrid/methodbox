class CartController < ApplicationController

  before_filter :login_required
  after_filter :update_last_user_activity
  #  before_filter :find_archives, :only => [ :index ]

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
  end

  def remove_from_cart
    case params[:submit]
    when "remove_variables"
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
    
    render :update, :status=>:created do |page|
      if !current_user.cart_items.empty?
        page.replace_html "table_header", :partial => "surveys/table_header",:locals=>{:sorted_variables => @sorted_variables}
        page.replace_html "table_container", :partial=>"surveys/table",:locals=>{:sorted_variables=>@sorted_variables,:lineage => false, :extract_lineage => false, :extract_id => nil}
        page.replace_html "cart_suggestions", :partial=>"cart/cart_suggestions", :locals=>{:target_matches=>@target_matches}
      else
        page.replace_html "cart_container", :partial => "cart/no_variables"
      end
    end
    when "create_archive"
      download_all_variables
    end
  end

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml 
    end
  end

end
