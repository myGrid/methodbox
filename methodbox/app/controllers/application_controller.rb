# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require_dependency File.join(Rails.root, 'vendor', 'plugins', 'annotations', 'lib', 'app', 'controllers', 'application_controller')
require 'fastercsv'
require 'net/http'
require 'xml'

class ApplicationController < ActionController::Base

  include AuthenticatedSystem
  
  helper :all # include all helpers, all the time
  layout "main"

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'cfb59feef722633aaee5ee0fd816b5fb'

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

  def add_to_cart

    if params[:year_of_survey]=="survey_year" && params[:watch_variable]=="false"
      #    @cart = find_cart
      @variable_list = Array.new(params[:variable_ids])

      @variable_list.each do |var|
        variable = Variable.find(var)
        session[:cart].add_variable(variable.id)
      end

      render :update, :status=>:created do |page|
        page.replace_html "cart-contents-inner", :partial=>"surveys/cart_item"
        page.replace_html "cart-total", :partial=>"surveys/cart_total"
      end
      
    elsif params[:watch_variable]=="false"
      varname = params[:variable_name]
      varid = params[:variable_identifier]
      variable = Variable.find(varid)
      curr_tags = variable.title_list

      surveyyear = params[:year_of_survey]
      @all_tags_array = Array.new
      param = varname+ surveyyear+'_variable_autocompleter_unrecognized_items'
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

      param1 = varname+ surveyyear+'_variable_autocompleter_selected_ids'
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
      curr_tags = variable.title_list
      curr_tags.each do |tag|
        str = str + tag + ","
      end

      puts "tagged with " + str
      variable.title_list = str
      variable.save_tags
      render :update, :status=>:created do |page|
         
      end
    elsif params[:watch_variable]=="true"
      #      user wants to watch a variable
      puts "watching " + params[:variable_identifier]
      var = Variable.find(params[:variable_identifier])
      person = Person.find(current_user.person_id)
      person.watched_variables.create(:variable_id => var.id)

      render :update, :status=>:created do |page|
      end
    else
      #      stop watching variable
      puts "stop watching " + params[:variable_identifier].to_s
      var = Variable.find(params[:variable_identifier])
      person = Person.find(current_user.person_id)
      watched = person.watched_variables.find(:all, :conditions => "variable_id=" + var.id.to_s)
      WatchedVariable.delete(watched)
      render :update, :status=>:created do |page|
      end
    end

  end
  def empty_cart
    session[:cart].items.clear
    render :update, :status=>:created do |page|
      page.replace_html "cart-contents-inner", :partial=>"surveys/cart_item"
      page.replace_html "cart-total", :partial=>"surveys/cart_total"
    end
  end

  def remove_selected
    logger.info("Remove selected")

    @var_list = params[:cart_ids]
    unless @var_list == nil
      @var_list.each do |var|
        session[:cart].items.delete_if{|ci| ci.id.to_s == var.to_s}
      end
    end
    render :update, :status=>:created do |page|
      page.replace_html "cart-contents-inner", :partial=>"surveys/cart_item"
      page.replace_html "cart-total", :partial=>"surveys/cart_total"
    end
  end

  def set_no_layout
    self.class.layout nil
  end

  def base_host
    request.host_with_port
  end
  
  def self.fast_auto_complete_for(object, method, options = {})
    define_method("auto_complete_for_#{object}_#{method}") do
      render :json => object.to_s.camelize.constantize.find(:all).map(&method).to_json
    end
  end

  #Overridden from restful_authentication
  #Does a second check that there is a profile assigned to the user, and if not goes to the profile
  #selection page (GET people/select)
  def authorized?
    if super
      redirect_to(select_people_path) if current_user.person.nil?
      true
    else
      false
    end
  end

  def is_user_activated
    if ACTIVATION_REQUIRED && current_user && !current_user.active?
      error("Activation of this account it required for gaining full access","Activation required?")
      false
    end
  end

  def is_current_user_auth
    begin
      @user = User.find(params[:id], :conditions => ["id = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("User not found (id not authorized)", "is invalid (not owner)")
      return false
    end
    
    unless @user
      error("User not found (or not authorized)", "is invalid (not owner)")
      return false
    end
  end
  
  def is_user_admin_auth
    unless current_user.is_admin?
      error("Admin rights required", "is invalid (not admin)")
      return false
    end
  end

  def logout_user
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    session[:user_id]=nil
    session[:cart] = nil
  end
  
  private

  #Get all values for a particular variable
  def get_variable(variable)
    
    survey_name = Survey.find(variable.survey_id).original_filename
    values_array = Array.new
    #open the dataset
    csvfile = FCSV.open( 'filestore/datasets/' + survey_name, :headers => true,  :return_headers => true,:col_sep => "\t")
    #skip past first line with the headers
    csvfile.gets
    #add the header as the first value of the array
    values_array.push(variable.name)
    #read each line of values
    while (line = csvfile.gets!=nil)
      #current value for this particular variable
      values_array.push(line.field[variable.name])
    end
    csvfile.close
    return values_array

  end

  def is_project_member

    if !Authorization.is_member?(current_user.person_id, nil, nil)
      flash[:error] = "Only members of known projects, institutions or work groups are allowed to create new content."
      redirect_to studies_path
    end

  end

  def error(notice, message)
    flash[:error] = notice
    (err = User.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to root_url }
    end
  end

  #The default for the number items in a page when paginating
  def default_items_per_page
    7
  end
  
  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password

  def find_cart
    session[:cart] ||= Cart.new
    #    @cart = session[:cart]
    #    if (@cart == nil)
    #      logger.info("Cart was nil, creating new")
    #      @cart = Cart.new
    #    end
  end



end
