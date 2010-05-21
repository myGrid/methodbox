require 'test_helper'

class ForumsControllerTest < ActionController::TestCase

  fixtures :forums, :users, :people

  include AuthenticatedTestHelper

  test "visible to admin" do

    login_as(:quentin)
    get :index
    assert_response :success
    assert_nil flash[:error]
  end

  test "visible to non admin" do
    login_as(:aaron)
    get :index
    assert_response :success
    assert_nil flash[:error]
  end

  test "invisible to not logged in" do
    get :index
    assert_response :redirect
    assert_redirected_to new_session_url
    assert_not_nil flash[:error]
  end
  
end
