require 'net/http'

class PeopleController < ApplicationController

  before_filter :login_required,:except=>[:select,:userless_project_selected_ajax,:create,:new]
  before_filter :current_user_exists,:only=>[:select,:userless_project_selected_ajax,:create,:new]
  before_filter :current_user_dormant,:except=>[:feed, :index,:new,:create,:select]
  before_filter :profile_belongs_to_current_or_is_admin, :only=>[:edit, :update,:destroy]
  before_filter :profile_is_not_another_admin_except_me, :only=>[:edit,:update,:destroy]
  before_filter :find_previous_searches, :only=>[ :show ]
  # before_filter :is_user_admin_auth, :only=>[:destroy]
  before_filter :is_user_admin_or_personless, :only=>[:new]
  before_filter :auth_params,:only=>[:update,:create]
  before_filter :set_tagging_parameters,:only=>[:edit,:new,:create,:update]
  before_filter :find_people, :init_atom_feed, :only => [:feed]
  after_filter :update_last_user_activity

  def auto_complete_for_tools_name
    render :json => Person.tool_counts.map(&:name).to_json
  end

  def auto_complete_for_expertise_name
    render :json => Person.expertise_counts.map(&:name).to_json
  end

  protect_from_forgery :only=>[]

  # GET /people
  # GET /people.xml
  def index

    if (!params[:expertise].nil?)
      @expertise=params[:expertise]
      people=Person.tagged_with(@expertise, :on=>:expertise)
      @people = people.paginate(:page=>params[:page] ? params[:page] : 1, :per_page=>default_items_per_page)
    else
      people = Person.all(:order=> "last_name, first_name")
      @people = people.paginate(:page=>params[:page] ? params[:page] : 1, :per_page=>default_items_per_page)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @people.to_xml}
    end
  end

  # GET /people/1
  # GET /people/1.xml
  def show
    @person = Person.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @person.to_xml}
    end
  end

  #def new = use User.new

  # GET /people/1/edit
  def edit
    @tags_tools = Person.tool_counts.sort{|a,b| a.name<=>b.name}
    @tags_expertise = Person.expertise_counts.sort{|a,b| a.name<=>b.name}

    @person = Person.find(params[:id])

    possible_unsaved_data = "unsaved_#{@person.class.name}_#{@person.id}".to_sym
    if session[possible_unsaved_data]
      # if user was redirected to this 'edit' page from avatar upload page - use session
      # data; alternatively, user has followed some other route - hence, unsaved session
      # data is most probably not relevant anymore
      if params[:use_unsaved_session_data]
        # NB! these parameters are admin settings and regular users won't (and MUST NOT)
        # be able to use these; admins on the other hand are most likely to never change
        # any avatars - therefore, it's better to hide these attributes so they never get
        # updated from the session
        #
        # this was also causing a bug: when "upload new avatar" pressed, then new picture
        # uploaded and redirected back to edit profile page; at this poing *new* records
        # in the DB for person's work group memberships would already be created, which is an
        # error (if the following 3 lines are ever to be removed, the bug needs investigation)
        session[possible_unsaved_data][:person].delete(:work_group_ids)
        session[possible_unsaved_data].delete(:can_edit_projects)
        session[possible_unsaved_data].delete(:can_edit_institutions)

        # update those attributes of a person that we want to be updated from the session
        @person.attributes = session[possible_unsaved_data][:person]
        @expertise_autocompleter_selected_ids = session[possible_unsaved_data][:expertise_autocompleter_selected_ids]
        @expertise_autocompleter_unrecognized_items = session[possible_unsaved_data][:expertise_autocompleter_unrecognized_items]
        #        @person.tool_list = session[possible_unsaved_data][:tool][:list]
               # @person.expertise_list = session[possible_unsaved_data][:expertise][:list]
      end

      # clear the session data anyway
      session[possible_unsaved_data] = nil
    end
  end

  #GET /people/select
  #
  #Page for after registration that allows you to select yourself from a list of
  #people yet to be assigned, or create a new one if you don't exist
#  def select
#    @userless_projects=Project.with_userless_people
#
#    #strip out project with no people with email addresses
#    #TODO: can be made more efficient by putting into a direct query in Project.with_userless_people - but not critical as this is only used during registration
#    @userless_projects = @userless_projects.select do |proj|
#      !proj.people.find{|person| !person.email.nil? && person.user.nil?}.nil?
#    end
#
#    @userless_projects.sort!{|a,b|a.name<=>b.name}
#    @person = Person.new
#
#    render :action=>"select",:layout=>"logged_out"
#  end


  #def create Use User.create

  # PUT /people/1
  # PUT /people/1.xml
  def update
    @person = Person.find(params[:id])

#    @person.disciplines.clear if params[:discipline_ids].nil?

    # extra check required to see if any avatar was actually selected (or it remains to be the default one)

    avatar_id = params[:person].delete(:avatar_id).to_i
    @person.avatar_id = ((avatar_id.kind_of?(Fixnum) && avatar_id > 0) ? avatar_id : nil)

    set_tools_and_expertise(@person,params)

    # some "Person" instances might not have a "User" associated with them - because the user didn't register yet
    if current_user.is_admin?
      unless @person.user.nil?
        @person.user.can_edit_projects = (params[:can_edit_projects] ? true : false)
        @person.user.can_edit_institutions = (params[:can_edit_institutions] ? true : false)
        @person.user.save
      end
    end

    respond_to do |format|
      if @person.update_attributes(params[:person]) 
        # && set_group_membership_role_ids(@person,params)
        @person.user.email = @person.email
        @person.user.save
        #        flash[:notice] = 'Person was successfully updated.'
        format.html { redirect_to(@person) }
        format.xml  { head :ok }
      else
        @expertise_autocompleter_selected_ids = params[:expertise_autocompleter_selected_ids]
        @expertise_autocompleter_unrecognized_items = params[:expertise_autocompleter_unrecognized_items]
        format.html { render :action => "edit" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  def set_group_membership_role_ids person,params
    #FIXME: Consider updating to Rails 2.3 and use Nested forms to handle this more cleanly.
    prefix="group_membership_role_ids_"
    person.group_memberships.each do |gr|
      key=prefix+gr.id.to_s
      gr.roles.clear
      if params[key.to_sym]
        params[key.to_sym].each do |r|
          r=Role.find(r)
          gr.roles << r
        end
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.xml
  def destroy
    person = Person.find(params[:id])
    person.dormant=true
    person.save
    user = User.find_by_person_id(person)
    user.dormant = true
    user.save
    if current_user == user
      current_user.forget_me
      reset_session
      respond_to do |format|
        format.html { redirect_to(root_url) }
        format.xml  { head :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to(admin_url) }
        format.xml  { head :ok }
      end
    end
  end

  def userless_project_selected_ajax
    project_id=params[:project_id]
    unless project_id=="0"
      proj=Project.find(project_id)
      #ignore people with no email address
      @people=proj.userless_people.select{|person| !person.email.blank? }
      @people.sort!{|a,b| a.last_name<=>b.last_name}
      render :partial=>"userless_people_list",:locals=>{:people=>@people}
    else
      render :text=>""
    end

  end
  #find any previous searches if you are looking at your own
  #profile
  def find_previous_searches
    search=[]
    if logged_in? && current_user.id == Person.find(params[:id]).user.id
      search = UserSearch.all(:order => "created_at DESC", :conditions => { :user_id => current_user.id})
    end
    @recent_searches = search
  end

  private
  
  def find_people
    @people = Person.all(:conditions=>{:dormant=>false})
  end

  def set_tools_and_expertise person,params

    tags=""
    params[:tools_autocompleter_selected_ids].each do |selected_id|
      tag=Tag.find(selected_id)
      tags << tag.name << ","
    end unless params[:tools_autocompleter_selected_ids].nil?
    params[:tools_autocompleter_unrecognized_items].each do |item|
      tags << item << ","
    end unless params[:tools_autocompleter_unrecognized_items].nil?

    person.tool_list=tags

    tags=""
    params[:expertise_autocompleter_selected_ids].each do |selected_id|
      tag=Tag.find(selected_id)
      tags << tag.name << ","
    end unless params[:expertise_autocompleter_selected_ids].nil?
    params[:expertise_autocompleter_unrecognized_items].each do |item|
      tags << item << ","
    end unless params[:expertise_autocompleter_unrecognized_items].nil?
    person.expertise_list=tags


  end

  def current_user_dormant
    if Person.find(params[:id]).dormant && !(current_user.is_admin? && ADMIN_CAN_SEE_DORMANT)
      flash[:notice] = "/people/"+params[:id] + " is not a valid account.  Please try again"
      redirect_to(:controller=>:people,:action=>:index)
      return
    end
  end

  def profile_belongs_to_current_or_is_admin
    @person=Person.find(params[:id])
    unless @person == current_user.person || current_user.is_admin?
      error("Not the current person", "is invalid (not owner)")
      return false
    end
  end

  def profile_is_not_another_admin_except_me
    @person=Person.find(params[:id])
    if !@person.user.nil? && @person.user!=current_user && @person.user.is_admin?
      error("Cannot edit another Admins profile","is invalid(another admin)")
      return false
    end
  end

  def is_user_admin_or_personless
    unless current_user.is_admin? || current_user.person.nil?
      error("You do not have permission to create new people","Is invalid (not admin)")
      return false
    end
  end

  def current_user_exists
    if !current_user
      redirect_to("/")
    end
    !!current_user
  end

  #checks the params attributes and strips those that cannot be set by non-admins, or other policy
  def auth_params
    if !current_user.is_admin?
      params[:person].delete(:is_pal) if params[:person]
    end
  end

  def set_tagging_parameters
    tools=Person.tool_counts.sort{|a,b| a.id<=>b.id}.collect{|t| {'id'=>t.id,'name'=>t.name}}
    @all_tools_as_json=tools.to_json

    expertise=Person.expertise_counts.sort{|a,b| a.id<=>b.id}.collect{|t|{'id'=>t.id,'name'=>t.name}}
    @all_expertise_as_json=expertise.to_json
  end
end
