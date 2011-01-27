# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  
  after_filter :update_last_user_activity

  layout 'main'

  # render new.rhtml
  def new

  end

  def create
    self.current_user = User.authenticate(params[:login], params[:password])
    if authorized?
      if params[:remember_me] == "1"
        current_user.remember_me unless current_user.remember_token?
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      if current_user.person.nil?
        logger.info("Attempt to access " + current_user.email + " but no person found.")
        flash[:error]="Sorry your person record is missing. Please contact an admin"
        session[:user_id]= nil
        redirect_to root_url
      elsif current_user.dormant?
        puts "current user dormant"
        if params[:cancel_dormant]
          current_user.dormant = false;
          current_user.save
          current_user.person.dormant = false;
          current_user.person.save
          redirect_to root_url
        else
          self.current_user.forget_me if logged_in?
          cookies.delete :auth_token
          reset_session
          flash[:notice] = "This account is no longer active."
          redirect_to :action => 'unsuspend', :controller => 'users'
        end
      else
        respond_to do |format|
#       flash[:notice] = "Logged in successfully"

          if !params[:called_from].blank? && params[:called_from][:controller] != "sessions"
            if !params[:called_from][:id].blank?
              return_to_url = url_for(:controller => params[:called_from][:controller], :action => params[:called_from][:action], :id => params[:called_from][:id])
            elsif !params[:called_from][:entry_ids].blank? && !params[:called_from][:survey_search_query].blank?             
              return_to_url = url_for(:controller => params[:called_from][:controller], :action => params[:called_from][:action], :entry_ids => params[:called_from][:entry_ids], :survey_search_query => params[:called_from][:survey_search_query])
            else
              return_to_url = url_for(:controller => params[:called_from][:controller], :action => params[:called_from][:action])
            end
          else
            if session[:return_to] and !session[:return_to].empty?
              return_to_url = session[:return_to]
            else
              return_to_url = root_url
            end
          end

          format.html { return_to_url.nil? || (return_to_url && URI.parse(return_to_url).path == '/') ? redirect_to(root_url) : redirect_to(return_to_url) }
        end
      end
    else
      #check if user is part way through registration processes
      user=User.find_by_email(params[:login])
      if user
        if !user.active?
          if user.approved?
            logger.info("Attempt to access "+user.email+" but account was not active.")
            flash[:error]=
            "You still need to activate your account. You should have been sent a validation email."
          else
            logger.info("Attempt to access "+user.email+" but account was not approved.")
            if user.created_at < 1.week.ago
              Mailer.deliver_signup_requested("Access requested over a week ago", user, base_host)
              flash[:error]="This account still has not been approved. The administrators have been reminded of your request. You will be sent an email when it has been authorized"
            else
              flash[:error]="This account has not yet beeen approved. You will be sent an email when it has been authorized"
            end
          end
          redirect_to root_url
        elsif (user.person.nil?)
          logger.info("Attempt to access "+user.email+" but no person found.")
          flash[:error]="Sorry your person record is missing. Please contact an admin"
          session[:user_id]= nil
          redirect_to root_url
        elsif !user.authenticated?(params[:password])
          logger.info("Attempt to access "+user.email+" with incorrect password.")
          flash[:error] = "User name or password incorrect, please try again"
          redirect_to :action => 'new'
        else
          logger.info(user.email)
          logger.info(user.active?)
          logger.info(user.activation_code)
          logger.info("Attempt to access "+user.email+" failed for unknown reason.")
          flash[:error]="Sorry there is a unexpected technical problem with your account. Please contact an admin"
          redirect_to root_url
        end
      else
        user = User.find_by_login(params[:login])
        if user
          if user.authenticated?(params[:password])
            logger.info("Attempt to access account using login "+params[:login]+" with correct password")
            flash[:error] = "Login has changed to using email. Yours is "+user.email.to_s
          else  
            logger.info("Attempt to access account using login "+params[:login]+" with incorrect password")
            flash[:error] = "Login has changed to using email."
          end
        else   
          if params[:login].match('@')
            logger.info("Attempt to access unknown account "+params[:login])
            flash[:error] = "User name or password incorrect, please try again"
          else  
            logger.info("Attempt to access account using unknown login "+params[:login])
            flash[:error] = "Login has changed to using email."
          end  
        end          
        redirect_to :action => 'new'
      end
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
#    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

end
