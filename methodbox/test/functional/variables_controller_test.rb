require 'test_helper'

class VariablesControllerTest < ActionController::TestCase

  test "visible to logged in" do
    login_as(:normal_user)
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

  #replicates bug for OBE-158
  test "show_variable" do
    post :show, :id => '89'
    assert_response :success
    assert_nil flash[:error]  
  end
end
