require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < ActionController::TestCase

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_title
   get :new
   if REGISTRATION_CLOSED
     assert_response :redirect
   else
     assert_response :success
     assert_select "title",:text=>/MethodBox.*/, :count=>1
   end
  end

  def test_should_allow_signup
    assert_difference 'User.count' do
      create_user
      assert_response :redirect
      user = User.find_by_email("quire@example.com")
      assert user.authenticated?('quire')
      if REGISTRATION_CLOSED
        assert user.dormant
        assert_nil user.activation_code
        assert_nil user.activated_at
      else
        assert !user.dormant
        if ACTIVATION_REQUIRED
          assert user.activation_code
          assert_nil user.activated_at
        else
          assert user.activated_at
          assert_nil user.activation_code
        end
      end
    end
  end

  def test_admin_signup_activation_done
    login_as :admin
    assert_difference 'User.count' do
      post :create, :user => { :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }, :person=>{:first_name=>"fred"}, :activate => true
      assert_response :redirect
      user = User.find_by_email("quire@example.com")
      assert user.authenticated?('quire')
      assert !user.dormant
      assert user.activated_at
      assert_nil user.activation_code
    end
  end

  def test_admin_signup_activation_required
    login_as :admin
    assert_difference 'User.count' do
      create_user
      assert_response :redirect
      user = User.find_by_email("quire@example.com")
      assert user.authenticated?('quire')
      assert !user.dormant
      assert user.activation_code
      assert_nil user.activated_at
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference 'User.count' do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'User.count' do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference 'User.count' do
      create_user(:email => nil)
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference 'User.count' do
      create_user(:email => nil)
    end
  end

  def test_should_not_allow_creating_an_admin
    assert_difference 'User.count' do
      create_user(:is_admin => true)
      u = User.find_by_email('quire@example.com')
      assert u
      assert !u.is_admin
    end
  end

  #  def est_should_sign_up_user_with_activation_code
  #    create_user
  #    assigns(:user).reload
  #    assert_not_nil assigns(:user).activation_code
  #  end

  def test_should_activate_user
    assert_nil User.authenticate('unactivated@example.com', 'test')
    get :activate, :activation_code => users(:unactivated_user).activation_code
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_redirected_to person_path(people(:unactivated_person).id)
    assert_equal users(:unactivated_user), User.authenticate('unactivated@example.com', 'test')
  end

  def test_should_not_activate_user_without_person
    assert_nil User.authenticate('unactivatedMissingPerson@example.com', 'est')
    get :activate, :activation_code => users(:unactivated_missing_person).activation_code
    assert_nil flash[:notice]
    assert_not_nil flash[:error]
    assert_redirected_to root_url
    assert_nil User.authenticate('unactivatedMissingPerson@example.com@example.com', 'est')
  end

  def test_should_not_activate_user_without_key
    get :activate
    assert_equal "Sorry account already activated or incorrect activation code. Please contact an admin.", flash[:error]
    assert_nil flash[:notice]
    assert_response :redirect
  end

  def test_should_not_activate_user_with_blank_key
    get :activate, :activation_code => ''
    assert_equal "Sorry account already activated or incorrect activation code. Please contact an admin.", flash[:error]
    assert_nil flash[:notice]
    assert_response :redirect
  end

  def test_can_edit_self
    login_as :normal_user
    get :edit, :id=>users(:normal_user)
    assert_response :success
    #assert_select "title",:text=>/MethodBox.*/, :count=>1
    #TODO: is there a better way to est the layout used?
    #assert_select "div#myexp_sidebar" #check its using the right layout
  end

  def test_cant_edit_some_else
    login_as :normal_user
    get :edit, :id=>users(:other_user)
    assert_redirected_to root_url
  end

  def test_update_password
    login_as :normal_user
    u=users(:normal_user)
    post :update, :id=>u.id, :user=>{:id=>u.id,:password=>"mmmmm",:password_confirmation=>"mmmmm"}
    assert_nil flash[:error]
    assert User.authenticate("aaron@example.com","mmmmm")
  end

  def test_reject_user
    login_as :admin
    u=users(:awaiting_approval)
    name = u.person.name
    assert_difference 'User.count', difference = -1 do
      post :reject, :id => u.id
      assert_nil flash[:error]
      assert_equal name + " has been deleted." , flash[:notice]
    end
   end

  def test_reject_user_removes_person
    login_as :admin
    u=users(:awaiting_approval)
    name = u.person.name
    assert_difference 'Person.count', difference = -1 do
      post :reject, :id => u.id
      assert_nil flash[:error]
      assert_equal name + " has been deleted." , flash[:notice]
    end
  end

  def test_approve_and_activate_user
    login_as :admin
    u=users(:awaiting_approval)
    post :approve, :id => u.id, :activate => true
    assert_nil flash[:error]
    assert_equal "Activated new user with email: "+u.email.to_s, flash[:notice]
  end

  def test_activate_user
    login_as :admin
    u=users(:unactivated_user)
    post :activate, :activation_code => u.activation_code
    assert_nil flash[:error]
    assert_equal u.person.name.to_s + " has been activated", flash[:notice]
    user = User.find(u)
    assert user.active?
  end

  def test_approve_but_not_activate_user
    login_as :admin
    u=users(:awaiting_approval)
    post :approve, :id => u.id
    assert_nil flash[:error]
    user = User.find(u)
    assert !user.active?
    assert_equal "Activation email sent to "+u.email.to_s, flash[:notice]
  end

  def test_resend_activation_code
    login_as :admin
    u=users(:unactivated_user)
    post :resend_actiavtion_code, :id => u.id
    user = User.find(u)
    assert !user.active?
    assert_nil flash[:error]
    assert_equal "Activation email sent to "+u.email.to_s, flash[:notice]
  end


  protected
  def create_user(options = {})
    post :create, :user => { :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options),:person=>{:first_name=>"fred"}
  end
end
