require File.dirname(__FILE__) + '/../test_helper'

class HomeControllerTest < ActionController::TestCase
  fixtures :people, :users

  include AuthenticatedTestHelper

  test "invisible to not logged in" do
    get :index
    assert_response :redirect
    assert_redirected_to :controller => "session", :action => "new"
    assert_not_nil flash[:error]
  end

  test "admin link not visible to non admin" do
    login_as(:aaron)
    get :index
    assert_response :success
    assert_nil flash[:error]
    assert_select "a[href=?]", admin_url, :text=>"Admin", :count=>0
  end

  test "admin tab visible to admin" do
    login_as(:quentin)
    get :index
    assert_response :success
    assert_nil flash[:error]
    assert_select "a[href=?]", admin_url, :text=>"Admin"
  end

  def test_title
    login_as(:quentin)
    get :index
    assert_select "title",:text=>/MethodBox.*/, :count=>1
  end

end
