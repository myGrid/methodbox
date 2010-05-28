require File.dirname(__FILE__) + '/../test_helper'
require 'sessions_controller'

# Re-raise errors caught by the controller.
class SessionsController; def rescue_action(e) raise e end; end

class SessionsControllerTest < ActionController::TestCase
 
  def setup
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_title
    get :new
    assert_select "title",:text=>/MethodBox.*/, :count=>1
  end

  def test_should_login_and_redirect
    post :create, :login => 'quentin@example.com', :password => 'test'
    assert_nil flash[:error]
    assert_nil flash[:notice]
    assert_response :redirect
    assert session[:user_id]
  end

  def test_bad_password
    post :create, :login => 'quentin@example.com', :password => 'bad password'
    assert_equal "User name or password incorrect, please try again", flash[:error]
    assert_nil flash[:notice]
    assert_nil session[:user_id]
    assert_redirected_to :controller => "session", :action => "new"
  end

  def test_unkown_user
    post :create, :login => 'badUser@example.com', :password => 'test'
    assert_equal "User name or password incorrect, please try again", flash[:error]
    assert_nil flash[:notice]
    assert_nil session[:user_id]
    assert_redirected_to :controller => "session", :action => "new"
  end

  def test_should_logout
    login_as :quentin
    get :destroy
    assert_nil flash[:error]
    assert_nil flash[:notice]
    assert_nil session[:user_id]
    assert_response :redirect
  end

  def test_should_remember_me
    post :create, :login => 'quentin@example.com', :password => 'test', :remember_me => "1"
    assert_not_nil @response.cookies["auth_token"]
  end

  def test_should_not_remember_me
    post :create, :login => 'quentin@example.com', :password => 'test', :remember_me => "0"
    assert_nil @response.cookies["auth_token"]
  end

  def test_should_delete_token_on_logout
    login_as :quentin
    get :destroy
    assert_nil @response.cookies["auth_token"], []
  end

  def test_should_login_with_cookie
    users(:quentin).remember_me
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    assert @controller.send(:logged_in?)
  end

  def test_should_fail_expired_cookie_login
    users(:quentin).remember_me
    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    assert !@controller.send(:logged_in?)
  end

  def test_should_fail_cookie_login
    users(:quentin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :new
    assert !@controller.send(:logged_in?)
  end
  
  def test_person_missing
    post :create, :login => 'person_missing@example.com', :password => 'test'
    assert_not_nil flash[:error]
    assert_nil flash[:notice]
    assert_nil session[:user_id]
    #assert_redirected_to :controller => "session", :action => "new"
  end

  def test_non_activated_user_should_redirect_to_new_with_message
    post :create, :login => 'unactivated@example.com', :password => 'test'
    assert_not_nil flash.now[:error]
    assert flash.now[:error].include?("need to activate")
    assert_nil flash.now[:notice]
    assert_nil session[:user_id]
    assert_redirected_to :action=>"new"
  end

  protected
    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end
    
    def cookie_for(user)
      auth_token users(user).remember_token
    end
end
