require File.dirname(__FILE__) + '/../test_helper'

class PeopleControllerTest < ActionController::TestCase


  def test_title
    login_as(:normal_user)
    get :index
    assert_select "title",:text=>/MethodBox.*/, :count=>1
  end

  def test_should_get_index
    login_as(:normal_user)
    get :index
    assert_response :success
    assert_not_nil assigns(:people)
  end

  #Throws an exception see OBE-128
  #def test_should_show_person
  #  get :show, :id => people(:one)
  #  assert_response :success
  #end

  #Throws an exception see OBE-128
  #def test_show_no_email
  #  get :show, :id => people(:one)
  #  assert_select "span.none_text", :text=>"Not specified"
  #end

  def test_should_get_edit
    login_as(:normal_user)
    get :edit, :id => people(:normal_person)
    assert_response :success
  end

  def test_non_admin_cant_edit_someone_else
    login_as(:normal_user)
    get :edit, :id=> people(:other_person)
    assert_redirected_to root_path
  end

  def test_admin_can_edit_others
    login_as(:admin)
    get :edit, :id=>people(:other_person)
    assert_response :success
  end

  #def test_can_edit_person_and_user_id_different
  #  #where a user_id for a person are not the same
  #  login_as(:fred)
  #  get :edit, :id=>people(:fred)
  #  assert_response :success
  #end

  def test_not_current_user_doesnt_show_link_to_change_password
    login_as(:admin)
    get :edit, :id => people(:other_person)
    assert_select "a", :text=>"Change password", :count=>0
  end

  #Throws an exception see OBE-128
  #def test_current_user_shows_seek_id
  #  get :show, :id=> people(:one)
  #  assert_select ".box_about_actor p",:text=>/Seek ID :/
  #  assert_select ".box_about_actor p",:text=>/Seek ID :.*#{people(:one).id}/
  #end

  def test_not_current_user_doesnt_show_seek_id
    login_as(:admin)
    get :show, :id=> people(:other_person)
    assert_select ".box_about_actor p",:text=>/Seek ID :/, :count=>0
  end

  #May 26, 2010. Test currently fails when work_groups fixture included.
  #def test_should_update_person
  #  put :update, :id => people(:one), :person => { }
  #  assert_redirected_to person_path(assigns(:person))
  #end

  def test_can_dormant_self
    login_as(:normal_user)
    delete :destroy, :id => people(:normal_person)
    assert_nil flash[:error]
    p = Person.find(people(:normal_person))
    assert p.dormant
    u = User.find_by_person_id(p)
    assert u.dormant
  end
  
  def test_can_not_dormant_others
    login_as(:normal_user)
    delete :destroy, :id => people(:other_person)
    assert_equal "Not the current person", flash[:error]
    p = Person.find(people(:other_person))
    assert !p.dormant
    u = User.find_by_person_id(p)
    assert !u.dormant
    p = Person.find(people(:normal_person))
    assert !p.dormant
    u = User.find_by_person_id(p)
    assert !u.dormant
  end
  
  def test_admin_can_dormant_others
    login_as(:admin)
    delete :destroy, :id => people(:other_person)
    assert_nil flash[:error]
    p = Person.find(people(:admin_person))
    assert !p.dormant
    u = User.find_by_person_id(p)
    assert !u.dormant
    p = Person.find(people(:other_person))
    assert p.dormant
    u = User.find_by_person_id(p)
    assert u.dormant
  end

end
