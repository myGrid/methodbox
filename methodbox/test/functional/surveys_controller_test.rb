require 'test_helper'

class SurveysControllerTest < ActionController::TestCase

  test "visible to logged in" do
    login_as(:aaron)
    get :index
    assert_response :success
    assert_nil flash[:error]
  end

  test "invisible to not logged in" do
    get :index
    assert_response :redirect
    assert_redirected_to :controller => "session", :action => "new"
    assert_not_nil flash[:error]
  end

  test "help visible to not logged in" do
    get :help
    assert_response :success
    assert_nil flash[:error]
  end

end
