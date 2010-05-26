require 'test_helper'

class AdminControllerTest < ActionController::TestCase

  test "visible to admin" do
    login_as(:quentin)
    get :show
    assert_response :success
    assert_nil flash[:error]
  end

  test "invisible to non admin" do
    login_as(:aaron)
    get :show
    assert_response :redirect
    assert_redirected_to :controller => "home", :action => "index"
    assert_not_nil flash[:error]
  end

  test "Illegal call to make self admin" do
    login_as(:aaron)
    aaron = users(:aaron)
    post :change_admin_status, :id => aaron.id, :is_admin => true
    assert_not_nil flash[:error]
    assert_redirected_to :controller => "home", :action => "index"
  end
  
  test "Legal call to make user admin" do
    login_as(:quentin)
    aaron = users(:aaron)
    post :change_admin_status, :id => aaron.id, :is_admin => true
    assert_nil flash[:error]
    assert_not_nil flash[:notice]
    assert_redirected_to :controller => "admin", :action => "index"
  end

  test "Illegal call to revoke own admin" do
    login_as(:quentin)
    quentin = users(:quentin)
    post :change_admin_status, :id => quentin.id, :is_admin => false
    quentin = users(:quentin)
    assert_not_nil flash[:error]
    assert_redirected_to :controller => "home", :action => "index"
  end

end
