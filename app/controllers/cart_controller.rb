class CartController < ApplicationController

  before_filter :login_required
  after_filter :update_last_user_activity
  #  before_filter :find_archives, :only => [ :index ]

  def show
    missing_vars=[]
    @archived_vars=[]
    @sorted_variables = Array.new
    
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
      #remove variables which are already in the cart
      matches.reject! {|match| current_cart.include?(match.target_variable_id)}
      if !matches.empty?
        @sorted_matches[var.id] = matches
      end
    end
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
      #remove variables which are already in the cart
      matches.reject! {|match| current_cart.include?(match.target_variable_id)}
      if !matches.empty?
        @sorted_matches[var.id] = matches
      end
    end
    
    render :update, :status=>:created do |page|
      if !current_user.cart_items.empty?
        page.replace_html "table_header", :partial => "surveys/table_header",:locals=>{:sorted_variables => @sorted_variables}
        page.replace_html "table_container", :partial=>"surveys/table",:locals=>{:sorted_variables=>@sorted_variables,:lineage => false, :extract_lineage => false, :extract_id => nil}
        page.replace_html "cart_suggestions", :partial=>"cart/cart_suggestions", :locals=>{:sorted_matches=>@sorted_matches}
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

  def deal_with_selected

    case params[:update_button]
    when "Download"
      logger.info("download selected")
      #    @var_list = params[:cart_ids]
      @var_list = params[:cart_ids]
      if @var_list == nil
        render :update, :status=>:created do |page|
          page.replace_html "progress_bar", :partial =>"surveys/try_again"
        end
      else
        puts @var_list
        download_selected

      end

    when "Remove"
      logger.info("Remove selected")

      @var_list = params[:cart_ids]
      if @var_list == nil
        render :update, :status=>:created do |page|
          page.replace_html "progress_bar", :partial =>"surveys/try_again"
        end
      else
        @var_list.each do |var|
          item = CartItem.find_by_user_id_and_variable_id(current_user,var)
          if item
            puts "delete" + var
            item.destroy
          end  
        end
        current_user.reload
        render :update, :status=>:created do |page|
          page.replace_html "cart-contents-inner", :partial=>"surveys/cart_item"
          page.replace_html "cart-total", :partial=>"surveys/cart_total"
        end
      end
    end

  end

  def download_selected

    logger.info("download selected variables")

    if @var_list == nil
      render :update, :status=>:created do |page|
        page.replace_html "progress_bar", :partial =>"surveys/try_again"
      end
    else
      @variable_hash = Hash.new
      @all_variables_array = Array.new
      @var_list.each do |var|
        puts "downloading " + var.to_s
        variable = Variable.find(var)
        if (!@variable_hash.has_key?(variable.survey_id))
          @variable_hash[variable.survey_id] = Array.new
        end
        @variable_hash[variable.survey_id].push(var)
        @all_variables_array.push(Variable.find(var))

      end


      @number_processed = 'Fill in the details for this new Archive'
      render :update, :status=>:created do |page|
        page.redirect_to(:controller => 'csvarchives', :action => 'new', :all_variables_array => @all_variables_array)
      end

    end
   
  end
#check if there are any variables in the cart.
#If there are then redirect to the new csvarchives page
  def download_all_variables
    logger.info("download all variables")

    if current_user.cart_items.empty?
      logger.info("cart was empty")
      render :update, :status=>:created do |page|
        page.replace_html "progress_bar", :partial =>"surveys/try_again"
      end
    else

      @number_processed = 'Fill in the details for this new Archive'
      render :update, :status=>:created do |page|
        page.redirect_to(:controller => 'csvarchives', :action => 'new')
      end

    end

  end

  def add_to_pseudo_cart
    render :update, :status=>:created do |page|
      
    end
  end

end
