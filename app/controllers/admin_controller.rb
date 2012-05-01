class AdminController < ApplicationController
  before_filter :authenticate_user!
  before_filter :is_user_admin_auth

  def show
    
  end
  
  def change_admin_status
    @user = User.find(params[:id])
    is_admin = params[:is_admin]
    if is_admin
      @user.is_admin = true
      @user.save
      if (current_user == @user)
        flash[:notice]="You are now an administrator."
      else
        flash[:notice]= @user.id.to_s + " is now an administrator."
      end
    else  
      if (User.count :conditions => "is_admin = true") == 1
        error("You can not revoke the last admin.", "is the last admin. Rovoke Rejected.")
        return
      end
      if (current_user == @user)
        error("As a safety feature you can not revoke your own admin rights. Ask another admin to do it for you.", "Attempt to revoke own admin rights blocked.")
        return
      end  
      @user.is_admin = false
      @user.save
      flash[:notice]= @user.id.to_s + " is no longer an administrator."
    end	      
    redirect_to :action => "index"
  end
  
end
