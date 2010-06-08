require 'test_helper'

class WorkGroupsControllerTest < ActionController::TestCase

  def est_title
    login_as :normal_user
    get :new
    assert_select "title",:text=>/MethodBox.*/, :count=>1
  end

  def test_create_work_group
    login_as :normal_user
    assert_difference 'WorkGroup.count' do
      create_work_group()
      assert_nil flash[:error]
    end
  end

  def test_create_no_group_refused
    login_as :normal_user
    assert_no_difference 'WorkGroup.count' do
      post :create
      assert_equal flash[:error], "Please use new form"
    end
  end

  def test_create_no_name_refused
    login_as :normal_user
    assert_no_difference 'WorkGroup.count' do
      create_work_group(:name => nil)
      assert_equal flash[:error], "Please use new form"
    end
  end

  def test_create_duplicate_name_refused
    login_as :normal_user
    assert_no_difference 'WorkGroup.count' do
      create_work_group(:name => "Sample Group")
      assert_equal flash[:error], "Title must be unique"
    end
  end

  protected
  def create_work_group(options = {})
    post :create, :group => {:name => 'A Test workgroup', :info => 'A bit of description', :user => users(:work_group_owner) }.merge(options) 
  end

end
