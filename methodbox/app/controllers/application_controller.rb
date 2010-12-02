# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require_dependency File.join(Rails.root, 'vendor', 'plugins', 'annotations', 'lib', 'app', 'controllers', 'application_controller')
require 'fastercsv'
require 'net/http'
require 'xml'

class ApplicationController < ActionController::Base

  include AuthenticatedSystem
  #email exceptions to nominated users
  include ExceptionNotification::Notifiable
  #https/ssl
  include SslRequirement

  helper :all # include all helpers, all the time
  layout "main"
  after_filter :discard_flash_if_xhr

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery  :secret => 'cfb59feef722633aaee5ee0fd816b5fb'

  def record_download resource
      download = Download.new
      download.resource_type = resource.class.name
      download.resource_id = resource.id
      download.user = current_user
      download.save
  end
  
  # the last time a user was logged in and actively clicked on something
  def update_last_user_activity
    if current_user
      current_user.update_attributes(:last_user_activity => Time.now)
    end
  end
  
  #savage_beast
  def update_last_seen_at
    if current_user
      current_user.update_attributes(:last_seen_at => Time.now)
    end
  end

  def admin?
    return current_user && current_user.is_admin?
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

  def download_all_variables
    logger.info("download all variables")

    if current_user.cart_items.empty?
      logger.info("cart was empty")
      render :update, :status=>:created do |page|
        page.replace_html "progress_bar", :partial =>"surveys/try_again"
      end
    else
      @variable_hash = Hash.new
      @all_variables_array = Array.new
      current_user.cart_items do |item|
        variable = Variable.find(item.variable_id)
        if (!@variable_hash.has_key?(variable.survey_id))
          @variable_hash[variable.survey_id] = Array.new
        end
        @variable_hash[variable.survey_id].push(item.variable_id)
        @all_variables_array.push(Variable.find(item.variable_id))
      end


      @number_processed = 'Fill in the details for this new Archive'
      render :update, :status=>:created do |page|
        page.redirect_to(:controller => 'csvarchives', :action => 'new', :all_variables_array => @all_variables_array)
      end

    end

  end

  def add_to_pseudo_cart
    render :update, :status=>:created do |page|

    end
  end

  def add_to_cart

    @submit = params[:submit]
#    req = "submit:\'"+@submit+ "\'"

    case params[:submit]
    when "link"
      @variable_list = Array.new(params[:variable_ids])
      if (!@variable_list.empty? && params[:link_variables_text]!="")
        link = VariableLink.new
        link.description = params[:link_variables_text]
        var_array = Array.new
        @variable_list.each do |var|
          variable = Variable.find(var)
          var_array.push(variable)
        end
        link.variables = var_array
        link.person_id = current_user.person_id
        link.save
        render :update, :status=>:created do |page|
        end
      else
        render :update, :status=>:created do |page|

        end
      end

    when "add"
      @selected_surveys = params[:survey_list]
      @variable_list = Array.new(params[:variable_ids])

      @variable_list.each do |var|

       if CartItem.find_by_user_id_and_variable_id(current_user,var)
       else
	  an_item = CartItem.new
          an_item.user = current_user
          an_item.variable_id = var
          an_item.save
          current_user.reload
        end
      end

      render :update, :status=>:created do |page|
        page.replace_html "cart_button", :partial=>"cart/button"
        page[:cart_button].visual_effect(:pulsate, :duration=>2.seconds)
      end

    when "search"
      @survey_search_query = params[:survey_search_query]
      @selected_surveys = Array.new(params[:survey_list])

      downcase_query = @survey_search_query.downcase
      search_terms = @survey_search_query.split(' ')
      if search_terms.length > 1
        downcase_query = @survey_search_query.downcase
        search_terms.unshift(downcase_query)
      end
      temp_variables = Array.new
      search_terms.each do |term|
        results = Variable.find_by_solr(term,:limit => 1000)
        variables = results.docs
        variables.each do |item|
          @selected_surveys.each do |ids|
            if Dataset.find(item.dataset_id).id.to_s == ids
              logger.info("Found " + item.name + ", from Survey " + item.dataset_id.to_s)
              temp_variables.push(item)
              break
            end
          end

        end
      end
      @sorted_variables = temp_variables
      case params[:add_results]
      when "no"
        render :update, :status=>:created do |page|
          page.replace_html "table_header", :partial=>"surveys/table_header",:locals=>{:sorted_variables=>@sorted_variables}
          page.replace_html "table_container", :partial=>"surveys/table",:locals=>{:sorted_variables=>@sorted_variables}
          page.insert_html(:bottom, "table_container", :partial=>"surveys/add_variables_div")
          page << %[dhtmlHistory.add("add_results_no", "new Ajax.Request('add_to_cart', {asynchronous:false, evalScripts:true, method:'post', parameters:#{req}});")]

          page << "uncheckAll();"
        end
      when "yes"
        remove_list = Array.new
        current_variables = params[:variable_list]
        @sorted_variables.each do |var|
          current_variables.each do |current_var|
            variable = Variable.find(current_var)
            if var.id == variable.id
              remove_list.push(var)
              break
            end
          end
        end
        remove_list.each do |var|
          @sorted_variables.delete(var)
        end
        all_search_variables = Array.new
        current_variables.each do |currvar|
          all_search_variables.push(currvar)
        end
        @sorted_variables.each do |sortvar|
          all_search_variables.push(sortvar.id.to_s)
        end
        current_variables.concat(@sorted_variables)

        var_req = "[{\'32653\':'a'},{\'32641\':'a'},{\'32648\':'a'}]"
        begin
        render :update, :status=>:created do |page|
          page.replace_html "table_header", :partial=>"surveys/table_header",:locals=>{:sorted_variables=>current_variables}
          page.replace_html "sorted_variables_div", :partial=>"surveys/sorted_variables_div",:locals=>{:sorted_variables=>@sorted_variables}
          page.insert_html(:before, "add_new_variables", :partial=>"surveys/table",:locals=>{:sorted_variables=>@sorted_variables})
          page << %[dhtmlHistory.add("add_results_yes", "new Ajax.Request('add_to_cart', {asynchronous:false, evalScripts:true, method:'post', parameters:{vars:#{var_req}} });")]
        end
        rescue
          logger.error($!)
        end
      end
    end
  end

  def empty_cart
    current_user.cart_items.destroy
    render :update, :status=>:created do |page|
      page.replace_html "cart-contents-inner", :partial=>"surveys/cart_item"
      page.replace_html "cart-total", :partial=>"surveys/cart_total"
    end
  end

  def remove_selected
    logger.info("Remove selected")

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

  def is_user_activated
    if ACTIVATION_REQUIRED && current_user && !current_user.active?
      if current_user.activation_code
      	error("Activation of this account it required for gaining full access","Activation required?")
      else
      	error("This account has not yet be authorized. You will be sent an email when it has been authorized","Authorization required?")
      end
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
      if (User.count :conditions => "is_admin = true") == 0
      	flash[:notice] = "No Admin User found. Set a user to admin ASAP."
      	return true
      end
      error("Admin rights required", "is invalid (not admin)")
      return false
    end
  end

  def logout_user
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    session[:user_id]=nil
  end

  protected
  
  #had to override this to test the exception notifier plugin
  #when running production locally.  Articles on web seem to say
  #you don't need to do this but I couldn't figure out another way
  def local_request?
    LOCAL_REQUEST_ERROR
  end
  

  #maybe use the breadcrumbs in the future
  #add one to a controller with eg. add_breadcrumb 'Home', 'index_url'

  #add little breadcrumbs to the routes
  #based on http://szeryf.wordpress.com/2008/06/13/easy-and-flexible-breadcrumbs-for-rails/
  def add_breadcrumb name, url = ''
    @breadcrumbs ||= []
    url = eval(url) if url =~ /_path|_url|@/
    @breadcrumbs << [name, url]
  end

  def self.add_breadcrumb name, url, options = {}
    before_filter options do |controller|
      controller.send(:add_breadcrumb, name, url)
    end
  end


  def discard_flash_if_xhr
    flash.discard if request.xhr?
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
    9
  end

  def default_variables_per_page
    30
  end
  
  #Check if someone is registered with the UKDA using their
  #web service (see UKDA_EMAIL_ADDRESS in environment_local.rb). It
  #takes a form with the persons email address and 'Login' submit button
  #params and returns some xml with a simple <registered>yes</registered>
  #or <registered>no</registered>
  # if the system is down then just check if they were ok a few months ago
  def ukda_registration_check(user)
    begin
      params={'LoginName' => user.email, 'Login' => 'Login'}
      response= Net::HTTP.post_form(URI.parse(UKDA_EMAIL_ADDRESS),params)
      xml_parser = XML::Parser.string(response.body)
      xml = xml_parser.parse
      node = xml.find('child::registered')
    rescue Exception => e
      # ukda reg check service probably down, default to looking at last time checked
      # if less than 6 months ago then say ok
      if user.last_ukda_check >= Time.now - (60 * 60 * 24 * 180)
        return true
      else
        return false
      end
    end
 
    if node.first.content == "yes"
      user.update_attributes(:last_ukda_check => Time.now, :ukda_registered => true)
      return true
    else
      user.update_attributes(:last_ukda_check => Time.now, :ukda_registered => false)
      return false
    end

  end

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password

end
