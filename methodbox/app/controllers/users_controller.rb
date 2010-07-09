class UsersController < ApplicationController

  layout "main", :except=>[:edit]

  before_filter :is_current_user_auth, :only=>[:edit, :update]
  before_filter :logged_out_or_admin, :only=>[:new, :create, :activate]
  before_filter :is_user_admin_auth, :only=>[:resend_actiavtion_code, :approve, :reject]
  before_filter :request_for_unactive_user, :only=>[:resend_actiavtion_code, :approve, :reject]
  before_filter :validate_create, :only=>[:create]
  # render new.rhtml
  def new
    @user=User.new
    @user.person=Person.new
    respond_to do |format|
      if current_user #and therefor by before_filter :can_create an admin
        #format.html {render :controller=>"users", :action => "new" }
        format.html {render :controller=>"users", :action => "add_user" }
      elsif REGISTRATION_CLOSED
        format.html {render :controller=>"users", :action => "request_access" }
      else  
        format.html {render :controller=>"users", :action => "new" }
      end  
    end
  end

  def create
    if !current_user
      cookies.delete :auth_token
      # protects against session fixation attacks, wreaks havoc with
      # request forgery protection.
      # uncomment at your own risk
      reset_session
    end
    @user = User.new(params[:user])
    @person = Person.new(params[:person])
    @person.email = @user.email
    @user.person=@person

    @user.save
    respond_to do |format|
    if @user.errors.empty?
      if current_user #and therefor by before_filter :logged_out_or_admin an admin
        do_approval(@user)
        Mailer.deliver_admin_created_account(current_user, @user, base_host)
        format.html {redirect_to(admin_path)}
      else
        if REGISTRATION_CLOSED
          Mailer.deliver_signup_requested(params[:message],@user,base_host)
          flash[:notice]="An email has been sent to the administor with your signup request."
          @user.dormant = true
          @user.person.dormant = true
          @user.activation_code = nil
          @user.save
          format.html {redirect_to(root_path)}
        else
          self.current_user = @user
          if !ACTIVATION_REQUIRED
            @user.activate
            @user.save
            format.html {redirect_to(root_path)}
            Mailer.deliver_welcome self.current_user, base_host
         else
              # Mailer.deliver_contact_admin_new_user_no_profile(member_details,current_user,base_host)
              Mailer.deliver_signup(current_user,base_host)
              flash[:notice]="An email has been sent to you to confirm your email address. You need to respond to this email before you can login"
              logout_user
              format.html {redirect_to(:controller=>"users",:action=>"activation_required")}
          end
        end
      end
    else
      #flash[:error] = "Something has gone wrong please check everything an try again"
      if REGISTRATION_CLOSED
        format.html {render :action => 'request_access'}
      else  
        format.html {render :action => 'new'}
      end  
    end
  end
  end

  def activate
    user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if !user
      logger.info("Activation code not found: "+params[:activation_code].to_s)
      flash[:error] = "Sorry account already activated or incorrect activation code. Please contact an admin."
      redirect_back_or_default('/')
    elsif !user.person
      logger.info("No person record found for user "+ user.person_id.to_s)
      flash[:error] = "Sorry account is corrupt. Please contact an admin."
      redirect_back_or_default('/')
    else  
      user.activate
      logger.info("New user activated: " + user.person_id.to_s)
      Mailer.deliver_welcome user, base_host
      if current_user #and therefor by before_filter :logged_out_or_admin an admin
         flash[:notice] = user.person.name.to_s+" has been activated"
         redirect_to admin_url
      else             
        self.current_user = user
        if logged_in?
          flash[:notice] = "You have succesfully signed up!"
          redirect_to self.current_user.person
        else
          #logger_in should have set flash[:error]
          logger.info("Login Failed for "+ self.current_user.person_id.to_s)
          flash[:error] = "login fialed"
          redirect_back_or_default('/')
        end #!logged_in?
      end #!current_user   
    end # user  &&  user.person
  end #def

  def reset_password
    user = User.find_by_reset_password_code(params[:reset_code])

    respond_to do |format|
      if user
        if user.reset_password_code_until && Time.now < user.reset_password_code_until
          user.reset_password_code = nil
          user.reset_password_code_until = nil
          if user.save
            self.current_user = user
            if logged_in?
              flash[:notice] = "You can change your password here"
              format.html { redirect_to(:action => "edit", :id => user.id) }
            else
              flash[:error] = "An unknown error has occurred. We are sorry for the inconvenience. You can request another password reset here."
              format.html { render :action => "forgot_password" }
            end
          end
        else
          flash[:error] = "Your password reset code has expired"
          format.html { redirect_to(:controller => "session", :action => "new") }
        end
      else
        flash[:error] = "Invalid password reset code"
        format.html { redirect_to(:controller => "session", :action => "new") }
      end
    end
  end

  def forgot_password
    if request.get?
      # forgot_password.rhtml
    elsif request.post?
      user = User.find_by_email(params[:email])

      respond_to do |format|
        if user && user.person && !user.dormant?
          user.reset_password_code_until = 1.day.from_now
          user.reset_password_code =  Digest::SHA1.hexdigest( "#{user.email}#{Time.now.to_s.split(//).sort_by {rand}.join}" )
          user.save!
          Mailer.deliver_forgot_password(user, base_host)
          flash[:notice] = "Instructions on how to reset your password have been sent to #{user.email}"
          format.html { render :action => "forgot_password" }
        else
          flash[:error] = "Invalid email: #{params[:email]}" if !user
          flash[:error] = "Account with email #{params[:email]} is corrupt. Please contact an admin." if user && (!user.person || user.dormant?)
          format.html { render :action => "forgot_password" }
        end
      end
    end
  end

  def edit
    @user = User.find(params[:id])
    render :action=>:edit, :layout=>"main"
  end

  def update
    @user = User.find(params[:id])

    person=Person.find(params[:user][:person_id]) unless (params[:user][:person_id]).nil?

    @user.person=person if !person.nil?

    @user.attributes=params[:user]

    if (!person.nil? && person.is_pal?)
      @user.can_edit_projects=true
      @user.can_edit_institutions=true
    end

    respond_to do |format|

      if @user.save
        #user has associated himself with a person, so activation email can now be sent
        if !current_user.active?
          Mailer.deliver_signup(@user,base_host)
          flash[:notice]="An email has been sent to you to confirm your email address. You need to respond to this email before you can login"
          logout_user
          format.html { redirect_to :action=>"activation_required" }
        else
          flash[:notice]="Your account details have been updated"
          format.html { redirect_to person_path(@user.person) }
        end
      else
        format.html { render :action => 'edit' }
      end
    end

  end

  def activation_required

  end
  
  def resend_actiavtion_code   
    user = User.find(params[:id])
    if user.activation_code
      flash[:notice]="Activation email sent to "+user.email.to_s
      Mailer.deliver_signup(user, base_host)
    else
      flash[:error]="User "+user.name+ " does not have an activation code"
    end
    redirect_to admin_url
  end
  
  def approve
    do_approval(User.find(params[:id]))
    redirect_to admin_url
  end
  
  def reject
    user = User.find(params[:id])
    name =  user.person.name.to_s 
    flash[:notice] = name + " has been deleted."
    Mailer.deliver_signup_request_denied(user,base_host)
    #user.person.destroy
    user.destroy
    redirect_to admin_url
  end

protected 
  def request_for_unactive_user
    user = User.find(params[:id])
    if !user
      error("No user found with id "+params[:id].to_s, "No user found")
      return false
    elsif user.active?
      error("User with id "+params[:id].to_s+ " already active", "User already active")
      return false
    else
      return true
    end  
  end

  def validate_create
    if !params[:user] || !params[:person] 
      flash[:error] = "Please use the signup form"
      redirect_to new_user_url    
    else  
      return true
    end      
  end

  def logged_out_or_admin
    return true if !current_user
    is_user_admin_auth
  end
  
  def do_approval(user)
    if params[:activate]
      user.activate
      flash[:notice]="Activated new user with email: "+user.email.to_s
      Mailer.deliver_welcome(user,base_host)
    else
      flash[:notice]="Activation email sent to "+user.email.to_s
      Mailer.deliver_signup(user,base_host)
    end
  end
  
end
