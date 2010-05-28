require 'test_helper'

class AdminControllerTest < ActionController::TestCase

  test "visible to admin" do
    login_as(:quentin)
    get :show
    assert_response :success
    assert_nil flash[:error]
    assert_nil flash[:notice]
  end

  test "invisible to non admin" do
    login_as(:aaron)
    get :show
    assert_equal "Admin rights required", flash[:error]
    assert_response :redirect
  end

  test "Illegal call to make self admin" do
    login_as(:aaron)
    aaron = users(:aaron)
    post :change_admin_status, :id => aaron.id, :is_admin => true
    assert_equal "Admin rights required", flash[:error]
    assert_response :redirect
  end
  
  test "Legal call to make user admin" do
    login_as(:quentin)
    aaron = users(:aaron)
    post :change_admin_status, :id => aaron.id, :is_admin => true
    assert_nil flash[:error]
    assert_match /is now an administrator./, flash[:notice]
    assert_response :redirect
  end

  test "Illegal call to revoke own admin" do
    login_as(:quentin)
    quentin = users(:quentin)
    post :change_admin_status, :id => quentin.id, :is_admin => false
    quentin = users(:quentin)
    assert_not_nil flash[:error]
    assert_response :redirect
  end

end
