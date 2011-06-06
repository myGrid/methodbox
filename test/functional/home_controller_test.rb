require File.dirname(__FILE__) + '/../test_helper'

class HomeControllerTest < ActionController::TestCase


  #May 28, 2010 Change of admin link under discussion
  #test "admin link not visible to non admin" do
  #  login_as(:aaron)
  #  get :index
  #  assert_response :success
  #  assert_nil flash[:error]
  #  assert_select "a[href=?]", admin_url, :text=>"Admin", :count=>0
  #end

  #May 28, 2010 Change of admin link under discussion
  #test "admin tab visible to admin" do
  #  login_as(:admin)
  #  get :index
  #  assert_response :success
  #  assert_nil flash[:error]
  #  assert_select "a[href=?]", admin_url, :text=>"Admin"
  #end

  def test_title
    login_as(:normal_user)
    get :index
    assert_select "title",:text=>/MethodBox.*/, :count=>1
  end

end
