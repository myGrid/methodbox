# encoding: UTF-8
require 'net/http'
require 'xml'

class ApplicationController < ActionController::Base

  #include AuthenticatedSystem
  #email exceptions to nominated users
  #include ExceptionNotification::Notifiable
  #https/ssl
  #include SslRequirement
  include SysMODB::SpreadsheetExtractor

  helper :all # include all helpers, all the time
  layout "main"
  after_filter :discard_flash_if_xhr

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery#  :secret => 'cfb59feef722633aaee5ee0fd816b5fb'

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || datasets_url
  end

  def truncate_words(text, length = 30, end_string = ' …')
    return if text == nil
    words = text.split()
    words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
  end

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

  def add_to_cart
    if params[:extract_id]
      extract_id_for_items = params[:extract_id]
    end
    if params[:search_terms]
      search_terms = Array.new(params[:search_terms])
      search_term_tracker = params[:search_term_tracker]
    end
    if params[:from_a_previous_search]
      previous_search_id = params[:from_a_previous_search]
    end


    case params[:value]
    when "add"
      @variable_list = Array.new(params[:variable_ids])

      @variable_list.each do |var|
        search_term_for_var = String.new
        if search_terms
          search_terms.each do |term|
            if search_term_tracker.has_key?(term)
              search_term_tracker[term].each do |search_term_hash|
                search_term_hash.each do |term_var|
                  if (term_var == var)
                    search_term_for_var = term
                    break
                  end
                end
              end
            end
          end
        elsif params[:survey_search_query]
            search_term_for_var = params[:survey_search_query]
        end
        
       if CartItem.find_by_user_id_and_variable_id(current_user,var)
         
       else
	       an_item = CartItem.new
         an_item.user = current_user
         an_item.variable_id = var
         if extract_id_for_items
           an_item.extract_id = extract_id_for_items
         end
         if previous_search_id
           an_item.user_search_id = previous_search_id
         end
         an_item.search_term = search_term_for_var
         an_item.save
         current_user.reload
       end
      end

      render :update, :status=>:created do |page|
        page.replace_html "cart-buttons", :partial=>"cart/all_buttons"
        #page.replace_html "create-data-extract-button", :partial=>"surveys/create_extract_button"
        page[:cart_button].visual_effect(:pulsate, :duration=>2)
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
    self.current_user.forget_me if user_signed_in?
    cookies.delete :auth_token
    session[:user_id]=nil
  end

  #
  # Generic Atom feed support code
  #

  # mark this page as containing a feed and set up the path to it
  def init_atom_feed
    @atom_feed = "#{params[:controller]}/feed"
  end

  # GET /:controller/feed/:id
  def feed
    respond_to do |format|
      format.atom { render :layout => false } # feed.atom.builder
    end
  end

  protected
  
  #To make it easier in dev mode using webrick etc this checks if you want
  #https.  Although the routes will be defined as https in the routes by default
  #you can override it by setting HTTPS_ON to false
#  def ssl_required?
#    HTTPS_ON
#  end
  
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
    12
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
      # if less than 6 months ago then say ok as long as they were previously ok
      if user.last_ukda_check != nil && user.last_ukda_check >= Time.now - (60 * 60 * 24 * 180) && user.ukda_registered
        return true
      else
        return false
      end
    end
 
    if node.first.content == "yes"
      puts "updating user ukda"
      user.update_attributes(:last_ukda_check => Time.now, :ukda_registered => true)
      return true
    else
      user.update_attributes(:last_ukda_check => Time.now, :ukda_registered => false)
      return false
    end

  end
  
  # Expire the surveys index fragment cache for each user
  def expire_survey_cache
    #a new dataset has been added so expire the surveys index fragment for all users 
    begin
      User.all.each do |user|
        fragment = 'surveys_index_' + user.id.to_s
        if fragment_exist?(fragment)
          logger.info Time.now.to_s + " New dataset so expiring cached fragment " + fragment
          expire_fragment(fragment)
        end
      end
      if fragment_exist?('surveys_index_anon')
        expire_fragment('surveys_index_anon')
      end
    rescue Exception => e
      logger.error Time.now.to_s + "Problem expiring cached fragment " + e.backtrace 
    end
  end

  #for the purpose of some user testing the surveys were restricted
  def get_surveys
    survey_types = SurveyType.where("name != ?", "test")
    non_empty_survey_types = []
    survey_types.each do |survey_type|
      any_datasets = false
      survey_type.surveys.each do |survey|
        any_datasets = true unless survey.datasets.empty?
      end
      if any_datasets 
        non_empty_survey_types << survey_type
      end
    end
    surveys = []
    non_empty_survey_types.each do |survey_type|
      survey_type.surveys.each do |survey|
        unless survey.datasets.empty? 
          surveys << survey unless !Authorization.is_authorized?("show", nil, survey, current_user)
        end
      end
    end
    return surveys
  end

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  #filter_parameter_logging :password

end
