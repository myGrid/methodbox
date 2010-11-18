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
  
#savage_beast
  def update_last_seen_at
    #return unless logged_in?
    #User.update_all ['last_seen_at = ?', Time.now.utc], ['id = ?', current_user.id]
    #current_user.last_seen_at = Time.now.utc
  end

  def admin?
    return current_user && current_user.is_admin?
  end

  # #savage_beast
  # def login_required
  #       if !current_user
  #                                 # redirect to login page
  #                                 return false
  #                         end
  #     end

      # def current_user
      #         #@current_user ||= ((session[:user_id] && User.find_by_id(session[:user_id])) || 0)
      #         @current_user = current_user
      #       end
      #savage_beast
      # def logged_in?
      #        current_user ? true : false #current_user != 0
      #      end
      #
      #      def admin?
      #        logged_in? && current_user.admin?
      #      end

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

    if current_user.cart_items.empty?
      logger.info("cart was empty")
      render :update, :status=>:created do |page|
        page.replace_html "progress_bar", :partial =>"surveys/try_again"
      end
    else
      @variable_hash = Hash.new
      @all_variables_array = Array.new
      current_user.cart_items do |item|
        puts "downloading " + item.variable_id.to_s
        variable = Variable.find(item.variable_id)
        if (!@variable_hash.has_key?(variable.survey_id))
          @variable_hash[variable.survey_id] = Array.new
        end
        @variable_hash[variable.survey_id].push(item.variable_id)
        @all_variables_array.push(Variable.find(item.variable_id))
        #        variable_hash[var] = get_variable(item.variable_id)
        #        logger.info("Would have downloaded: " + item.variable_id.to_s)
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

          #        TODO flash a message
          #        page.replace_html "cart-contents-inner", :partial=>"surveys/cart_item"
          #        page.replace_html "cart-total", :partial=>"surveys/cart_total"
        end
      else
        render :update, :status=>:created do |page|

          #        TODO flash error message
          #        page.replace_html "cart-contents-inner", :partial=>"surveys/cart_item"
          #        page.replace_html "cart-total", :partial=>"surveys/cart_total"
        end
      end

    when "add"
      @selected_surveys = params[:survey_list]
      @variable_list = Array.new(params[:variable_ids])

      @variable_list.each do |var|

       #uts CartItem.find(:first)
       #uts CartItem.find_by_user_id(current_user)
       if CartItem.find_by_user_id_and_variable_id(current_user,var)
          puts "User already has variable "+var.to_s
       else
	  an_item = CartItem.new
          an_item.user = current_user
          an_item.variable_id = var
          an_item.save
          current_user.reload
          #uts "cart size is now "+ current_user.cart_items.size.to_s
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

    when "search"
      @survey_search_query = params[:survey_search_query]
      @selected_surveys = Array.new(params[:survey_list])
      #    logger.info("length " + @survey_list.size)
      #    @search_query||=""

      downcase_query = @survey_search_query.downcase
      search_terms = @survey_search_query.split(' ')
      if search_terms.length > 1
        downcase_query = @survey_search_query.downcase
        search_terms.unshift(downcase_query)
      end
      temp_variables = Array.new
      puts "searching for " + search_terms.to_s
      search_terms.each do |term|
        #      @results = Variable.find_by_solr(downcase_query,:limit => 1000)
        results = Variable.find_by_solr(term,:limit => 1000)
        variables = results.docs
        variables.each do |item|
          @selected_surveys.each do |ids|
            if Dataset.find(item.dataset_id).id.to_s == ids
              logger.info("Found " + item.name + ", from Survey " + item.dataset_id.to_s)
              puts "Found " + item.name + ", from Survey " + item.dataset_id.to_s
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
#          page << %[dhtmlHistory.add("table_header", "new Ajax.Request('surveys/table_header', {asynchronous:false, evalScripts:true, method:'post'});")]
          page << %[dhtmlHistory.add("add_results_no", "new Ajax.Request('add_to_cart', {asynchronous:false, evalScripts:true, method:'post', parameters:#{req}});")]

          #if any of the checkboxes had been selected then uncheck them by calling the javascript function
          page << "uncheckAll();"
        end
      when "yes"
      #  request = "new Ajax.Request('add_to_cart', {asynchronous:false, evalScripts:true, method:'post', parameters:" +req + "});"
        #remove any variables from the new search which were in the old search
        remove_list = Array.new
        current_variables = params[:variable_list]
        @sorted_variables.each do |var|
          current_variables.each do |current_var|
            variable = Variable.find(current_var)
            if var.id == variable.id
              remove_list.push(var)
              puts "match " + var.id.to_s + " " + variable.id.to_s
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

        puts "current variables: " + all_search_variables.to_json
#         req = all_search_variables.to_json
#        var_req = "variables:" + all_search_variables.to_json.to_s
        var_req = "[{\'32653\':'a'},{\'32641\':'a'},{\'32648\':'a'}]"
        begin
        render :update, :status=>:created do |page|
          page.replace_html "table_header", :partial=>"surveys/table_header",:locals=>{:sorted_variables=>current_variables}
          page.replace_html "sorted_variables_div", :partial=>"surveys/sorted_variables_div",:locals=>{:sorted_variables=>@sorted_variables}
          page.insert_html(:before, "add_new_variables", :partial=>"surveys/table",:locals=>{:sorted_variables=>@sorted_variables})
#          page << %[dhtmlHistory.add("table_header", "new Ajax.Request('surveys/table_header', {asynchronous:false, evalScripts:true, method:'post'});")]
          page << %[dhtmlHistory.add("add_results_yes", "new Ajax.Request('add_to_cart', {asynchronous:false, evalScripts:true, method:'post', parameters:{vars:#{var_req}} });")]
#          page << %[dhtmlHistory.add("add_results_yes", #{request})]
          #if any of the checkboxes had been selected then uncheck them by calling the javascript function
          #          page << "uncheckAll();"
        end
        rescue
          puts "error " + $!
        end
      end
      #      respond_to do |format|
      #puts "doing some rendering"
      #       format.html { redirect_to search_variables_surveys_path }
      #       puts "done it"
      #      end
    end

    #    if params[:year_of_survey]=="survey_year" && params[:watch_variable]=="false"
    #    @cart = find_cart
    #      @selected_surveys = params[:survey_list]
    #      @variable_list = Array.new(params[:variable_ids])
    #
    #      @variable_list.each do |var|
    #        variable = Variable.find(var)
    #        session[:cart].add_variable(variable.id)
    #      end
    #
    #      render :update, :status=>:created do |page|
    #        page.replace_html "cart-contents-inner", :partial=>"surveys/cart_item"
    #        page.replace_html "cart-total", :partial=>"surveys/cart_total"
    #      end

    #    elsif params[:watch_variable]=="false"
    #      varname = params[:variable_name]
    #      varid = params[:variable_identifier]
    #      variable = Variable.find(varid)
    #      curr_tags = variable.title_list
    #
    #      surveyyear = params[:year_of_survey]
    #      @all_tags_array = Array.new
    #      param = varname+ surveyyear+'_variable_autocompleter_unrecognized_items'
    #      #      param2 = varname +surveyyear +'_variable_autocompleter_selected_ids'
    #      taghash = params[param]
    #      #      oldtaghash = params[param2]
    #      #      if oldtaghash != nil
    #      #        oldtaghash.each do |oldtag|
    #      #          @all_tags_array.push(Tag.find(oldtag).name)
    #      #        end
    #
    #
    #      if taghash != nil
    #        if !taghash.empty?
    #
    #          taghash.each do |tag|
    #            @all_tags_array.push(tag.to_s)
    #            #            data = {"tag"=>[tag.to_s]}
    #            #            variable = Variable.find(varid)
    #            #            variable.create_annotations(data,person)
    #            puts "new tag: " + tag
    #          end
    #
    #
    #
    #        end
    #
    #      end
    #
    #      # cope with new tags that have been added by clicking on the suggestions box
    #
    #      param1 = varname+ surveyyear+'_variable_autocompleter_selected_ids'
    #      taghash2 = params[param1]
    #
    #
    #      if taghash2 != nil
    #        if !taghash2.empty?
    #
    #          taghash2.each do |tag|
    #            ntag = Tag.find(tag)
    #            @all_tags_array.push(ntag.name)
    #            #            data = {"tag"=>[tag.to_s]}
    #            #            variable = Variable.find(varid)
    #            #            variable.create_annotations(data,person)
    #            puts "new tag: " + tag
    #          end
    #
    #
    #
    #        end
    #
    #      end
    #
    #      str = ""
    #      #        puts "curr user " + current_user.id.to_s
    #      #        person = Person.find(current_user.id)
    #      @all_tags_array.each do |newtag|
    #        str =str + newtag +","
    #      end
    #      curr_tags = variable.title_list
    #      curr_tags.each do |tag|
    #        str = str + tag + ","
    #      end
    #
    #      puts "tagged with " + str
    #      variable.title_list = str
    #      variable.save_tags
    #      render :update, :status=>:created do |page|
    #
    #      end
    #      #remove the watch variable stuff for the moment
    #      #    elsif params[:watch_variable]=="true"
    #      #      #      user wants to watch a variable
    #      #      puts "watching " + params[:variable_identifier]
    #      #      var = Variable.find(params[:variable_identifier])
    #      #      person = Person.find(current_user.person_id)
    #      #      person.watched_variables.create(:variable_id => var.id)
    #      #
    #      #      render :update, :status=>:created do |page|
    #      #      end
    #      #    else
    #      #      #      stop watching variable
    #      #      puts "stop watching " + params[:variable_identifier].to_s
    #      #      var = Variable.find(params[:variable_identifier])
    #      #      person = Person.find(current_user.person_id)
    #      #      watched = person.watched_variables.find(:all, :conditions => "variable_id=" + var.id.to_s)
    #      #      WatchedVariable.delete(watched)
    ##      render :update, :status=>:created do |page|
    ##      end
    #    end

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
          puts "delete" + var
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
      puts "crumb for " + name + " " + url
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
  def ukda_registration_check(person)
   # params={'LoginName' => person.email, 'Login' => 'Login'}
   # response= Net::HTTP.post_form(URI.parse(UKDA_EMAIL_ADDRESS),params)
   # xml_parser = XML::Parser.string(response.body)
   # xml = xml_parser.parse
   # node = xml.find('child::registered')
   # return node.first.content == "yes"
   #  This stuff isn't working reliably so we will just default to true
   #  and fallback to the everyone registered is vetted by us
   return true
  end

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password

end
