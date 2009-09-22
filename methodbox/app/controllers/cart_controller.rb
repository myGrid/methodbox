class CartController < ApplicationController

  before_filter :login_required
  before_filter :find_archives, :only => [ :index ]

  def deal_with_selected
    #        logger.info("commit: " + params[:myHiddenField])
    #    if params.has_key?(:download_button)
    #      redirect_to :action => "download_selected"
    #
    #    else
    #      redirect_to :action => "remove_selected"
    #    end
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
          session[:cart].items.delete_if{|ci| ci.id.to_s == var.to_s}
        end
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
        #        variable_hash[var] = get_variable(var)
        #        logger.info("Would have downloaded: " + var.to_s)
      end


      @number_processed = 'Fill in the details for this new Archive'
      render :update, :status=>:created do |page|
        #        page.replace_html "progress_bar", :partial =>"surveys/progress_bar"
        page.redirect_to(:controller => 'csvarchives', :action => 'new', :all_variables_array => @all_variables_array)
      end

    end
   
  end

  def download_all_variables
    logger.info("download all variables")

    if session[:cart].items.empty?
      logger.info("cart was empty")
      render :update, :status=>:created do |page|
        page.replace_html "progress_bar", :partial =>"surveys/try_again"
      end
    else
      @variable_hash = Hash.new
      @all_variables_array = Array.new
      session[:cart].items.each do |var|
        puts "downloading " + var.to_s
        variable = Variable.find(var)
        if (!@variable_hash.has_key?(variable.survey_id))
          @variable_hash[variable.survey_id] = Array.new
        end
        @variable_hash[variable.survey_id].push(var)
        @all_variables_array.push(Variable.find(var))
        #        variable_hash[var] = get_variable(var)
        #        logger.info("Would have downloaded: " + var.to_s)
      end
     

      @number_processed = 'Fill in the details for this new Archive'
      render :update, :status=>:created do |page|
        #        page.replace_html "progress_bar", :partial =>"surveys/progress_bar"
        page.redirect_to(:controller => 'csvarchives', :action => 'new', :all_variables_array => @all_variables_array)
      end

    end

  end

  def add_to_pseudo_cart
    render :update, :status=>:created do |page|
      
    end
  end

end
