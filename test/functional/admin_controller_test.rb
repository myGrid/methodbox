require 'test_helper'

class AdminControllerTest < ActionController::TestCase

  test "visible to admin" do
    login_as(:admin)
    get :show
    assert_response :success
    assert_nil flash[:error]
    assert_nil flash[:notice]
  end

  test "invisible to non admin" do
    login_as(:normal_user)
    get :show
    assert_equal "Admin rights required", flash[:error]
    assert_response :redirect
  end

  test "Illegal call to make self admin" do
    login_as(:normal_user)
    aaron = users(:normal_user)
    post :change_admin_status, :id => aaron.id, :is_admin => true
    assert_equal "Admin rights required", flash[:error]
    assert_response :redirect
  end
  
  test "Legal call to make user admin" do
    login_as(:admin)
    aaron = users(:normal_user)
    post :change_admin_status, :id => aaron.id, :is_admin => true
    assert_nil flash[:error]
    assert_match /is now an administrator./, flash[:notice]
    assert_response :redirect
  end

  test "Illegal call to revoke own admin" do
    login_as(:admin)
    admin = users(:admin)
    post :change_admin_status, :id => admin.id, :is_admin => false
    admin = users(:admin)
    assert_not_nil flash[:error]
    assert_response :redirect
  end

end
