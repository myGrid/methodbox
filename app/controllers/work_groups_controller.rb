require 'white_list_helper'

class WorkGroupsController < ApplicationController
  include WhiteListHelper
  
  before_filter :authenticate_user!
  before_filter :find_people, :only => [:new,:edit,:create]
  before_filter :set_no_layout, :only => [ :review_popup ]
  before_filter :find_work_group, :only => [ :review_popup ]
  before_filter :find_work_group_auth, :only => [ :edit ]
  before_filter :unique_name, :only => [ :create ]
  
  protect_from_forgery :except => [ :review_popup ]
  
  def request_access
    @group = WorkGroup.find(params[:id])
    
      @message = Message.new
      @message.from ||= User.find(current_user.id).person_id
      @message.to = User.find(@group.user_id).person_id
      # set initial datetimes
      @message.read_at = nil
      @message.subject = "Request for group access"
      @message.body = User.find(current_user.id).person.name + " would like access to your MethodBox group " + @group.name + "\nTo add them to your group go to " + "http://" + base_host + "/work_groups/" + @group.id.to_s + "/edit"     
      
    respond_to do |format|
        if @message.save
          begin
            Mailer.deliver_work_group_request(@message,base_host) if EMAIL_ENABLED && Person.find(@message.to).send_notifications?
          rescue Exception => e
            logger.error("ERROR: failed to send New Message email notification. Message ID: #{@message.id}")
            logger.error("EXCEPTION: " + e)
          end
          #internal message will work even if the email doesn't
          flash[:notice] = 'Message was successfully sent.'
          format.html { redirect_to work_group_url(@group) }
        else 
          puts @message.errors.full_messages.to_sentence
          flash[:error] = "Message could not be sent, please try later."
          format.html { redirect_to work_group_url(@group) }
        end
      end  
  end
  
  # GET /groups
  # GET /groups.xml
  def index
    @groups = WorkGroup.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    @group = WorkGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = WorkGroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = WorkGroup.find(params[:id])
  end

  # POST /groups
  # POST /groups.xml
  def create
    @group = WorkGroup.new(params[:group])
    if params[:people] != nil
      @group.person_ids = params[:people]
    end
    @group.user = current_user

    respond_to do |format|
      if @group.save
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to(@group) }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        puts @group.errors
        flash[:error] = 'Could not create the group. Please try again.'
        format.html { render :action => "new" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end
  
   # POST /groups
   # POST /groups.xml
   # experimental ajax style create for inline creation of workgroups along with link_to_remote and RedBox popup
   # def create
   #   @group = WorkGroup.new
   #   @group.name = params[:group_name]
   #   @group.info = params[:group_desc]
   #   if params[:people] != nil
   #     @group.person_ids = params[:people]
   #   end
   # 
   #   respond_to do |format|
   #     if @group.save
   #       # flash[:notice] = 'Group was successfully created.'
   #       render :update, :status=>:created do |page|
   #         page.insert_html(:before, "groups_table_source_bottom", :partial => "assets/selector_source_row",:locals=>{:resource_id => "groups", :item=>@group, :hidden=>false})
   #         page.insert_html(:before, "groups_table_target_bottom", :partial => "assets/selector_target_row",:locals=>{:resource_id => "groups", :item=>@group, :hidden=>true})
   #         # page << $('groups_source_table_body').down('tr').insert(after
   #         # page << "addNewWorkgroup(#{"groups"},#{@group.id},#{@group.name})"
   #       end
   #       # format.html { redirect_to(@group) }
   #       # format.xml  { render :xml => @group, :status => :created, :location => @group }
   #     else
   #       puts @group.errors
   #       flash[:error] = 'Could not create the group. Please try again.'
   #       format.html { render :action => "new" }
   #       format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
   #     end
   #   end
   # end
  
  
  # POST /work_groups/review
  # will be called to display the RedBox popup for reviewing member permissions of workgroup
  # (or project / institutions - as these are, essentially, work groups, too)
  def review_popup
    respond_to do |format|
      format.js # review_popup.html.erb
    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = WorkGroup.find(params[:id])
      people_array = [] 
      if params[:people] != nil
      params[:people].each do |person_id|
        people_array.push(Person.find(person_id))
      end
    end
    params[:group][:people] = people_array
    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to(@group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = WorkGroup.find(params[:id])
    begin 
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(work_groups_url) }
      format.xml  { head :ok }
    end
  rescue   Exception => exc
     respond_to do |format|
       puts exc.message
       flash[:error] = "#{exc.message}"
       format.html {redirect_to(work_group_url(@group)) }
     end
  end
  end
  
  protected
  
  # Currently only the person who created the group can edit it, add people etc.
  def find_work_group_auth
    begin
      group = WorkGroup.find(params[:id])             
      
      if group.user == current_user
        @group = group
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to work_groups_path }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the WorkGroup or you are not authorized to view it"
        format.html { redirect_to work_groups_path }
      end
      return false
    end
  end
  
  
  private
  
  def find_people
    @people = Person.find(:all, :conditions => ["dormant = ?", false])
  end
  
  def find_work_group
    # work group members list is public - no need for any security checks
    group_type = white_list(params[:type])
    group_id = white_list(params[:id])
    access_type = white_list(params[:access_type]).to_i
    
    begin
      group_instance = eval("#{group_type}.find(#{group_id})")
      @error_text = nil
      @group_instance = group_instance
      case @group_instance.class.name
        when "WorkGroup"
          @group_name = @group_instance.project.name + " @ " + @group_instance.institution.name
        when "Project", "Institution"
          @group_name = @group_instance.name
        else
          @group_name = "unknown"
      end
      @access_type = access_type
      
    rescue ActiveRecord::RecordNotFound
      @error_text = "#{group_type} with ID = #{group_id} wasn't found."
    rescue NameError
      @error_text = "Unknown work group type: #{group_type}"
    end
    
    respond_to do |format|
      format.js # review_popup.html.erb
    end
  end
  
  def unique_name
    if params[:group] && params[:group][:name]
      !WorkGroup.find_by_name(params[:group][:name]) || redirect_to_new("Title must be unique")
    else
      redirect_to_new  
    end  
  end
  
  # Redirect as appropriate when an create request fails.
  #
  # The default action is to redirect to the create screen.
  def redirect_to_new(message = "Please use new form")
    respond_to do |format|
      format.html do
        flash[:error] = message
        redirect_to new_work_group_path
      end
      format.any do
        request_http_basic_authentication message
      end
    end
  end

end
