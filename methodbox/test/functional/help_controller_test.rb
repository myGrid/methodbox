require 'test_helper'

class HelpControllerTest < ActionController::TestCase

  fixtures :users, :people

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

  test "visible to not logged in" do
    get :index
    assert_response :success
    assert_nil flash[:error]
  end

end
