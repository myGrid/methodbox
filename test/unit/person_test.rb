require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  
  #Poeple without name not supported
  #def test_registered
  #  registered=Person.registered
  #  registered.each do |p|
  #    assert_not_nil p.user
  #  end
  #  assert registered.include?(people(:normal_person))
  #  assert !registered.include?(people(:unactivated_person))
  #end

  #to look at when doing groups
  #def test_without_group
  #  without_group=Person.without_group
  #  without_group.each do |p|
  #    assert_equal 0,p.group_memberships.size
  #  end
  #  assert !without_group.include?(people(:one))
  #  assert without_group.include?(people(:person_without_group))
  #end

  #June 8 to do with new fixtures
  #def xest_expertise
  #  p=people(:one)
  #  assert_equal 2, p.expertise.size

  #  p=people(:two)
  #  assert_equal 1, p.expertise.size
  #  assert_equal "golf",p.expertise[0].name
  #end
    
  #May 25, 2010 Projects are currently not supported
  #def xest_projects
  #  p=people(:one)
  #  assert_equal 2,p.projects.size
  #end
  
  #June 8 No longer doing userless people
  #def xest_userless_people
  #  peeps=Person.userless_people
  #  assert_not_nil peeps
  #  assert peeps.size>0,"There should be some userless people"
  # assert_nil peeps.find{|p| !p.user.nil?},"There should be no people with a non nil user"    

  #  p=people(:three)
  #  assert_not_nil peeps.find{|person| p.id==person.id},"Person :three should be userless and therefore in the list"

  #  p=people(:one)
  #  assert_nil peeps.find{|person| p.id==person.id},"Person :one should have a user and not be in the list"
  #end

  def test_name
      p=people(:normal_person)
      assert_equal "Aaron Spiggle", p.name
      p.first_name="Tom"
      assert_equal "Tom Spiggle", p.name
  end

  def test_email_with_name
    p=people(:normal_person)
    assert_equal("Aaron Spiggle <aaron@example.com>",p.email_with_name)
  end
  
  def test_capitalization_with_no_first_name
    p=create_person(:first_name => nil)
    assert_equal " Tomson",p.name
  end

  def test_capitalization_with_no_last_name
    p=create_person(:last_name => nil)
    assert_equal "Micheal ",p.name
  end

  def test_double_firstname_capitalised
    p=create_person(:first_name => "fred david")
    assert_equal "Fred David Tomson", p.name
  end

  def test_double_lastname_capitalised
    p=create_person(:last_name => "smith jones")
    assert_equal "Micheal Smith Jones",p.name
  end

  def test_double_barrelled_lastname_capitalised
    p=create_person(:last_name => "smith-jones")
    assert_equal "Micheal Smith-Jones",p.name
  end

  def test_valid
    p=people(:normal_person)
    assert p.valid?
    p.email=nil
    assert !p.valid?

    p.email="sdf"
    assert !p.valid?

    p.email="sdf@"
    assert !p.valid?

    p.email="sdf@com"
    assert !p.valid?

    p.email="sdaf@sdf.com"
    assert p.valid?

    p.web_page=nil
    assert p.valid?

    p.web_page=""
    assert p.valid?

    p.web_page="sdfsdf"
    assert !p.valid?

    p.web_page="http://google.com"
    assert p.valid?

    p.web_page="https://google.com"
    assert p.valid?

    p.web_page="http://google.com/fred"
    assert p.valid?

    p.web_page="http://google.com/fred?param=bob"
    assert p.valid?

    p.web_page="http://www.mygrid.org.uk/dev/issues/secure/IssueNavigator.jspa?reset=true&mode=hide&sorter/order=DESC&sorter/field=priority&resolution=-1&pid=10051&fixfor=10110"
    assert p.valid?
  end

  def test_email_unique
    p=people(:normal_person)
    newP=Person.new(:first_name=>"Fred",:last_name=>"Smith",:email=>p.email)
    assert !newP.valid?,"Should not be valid as email is not unique"
    newP.email="zxczxc@zxczxczxc.com"
    assert newP.valid?
  end

protected
  def create_person(options = {})
    p = Person.new({ :email => 'micheal@example.com', :first_name => "Micheal", :last_name => "Tomson"}.merge(options))
    p.save
    p
  end

 end
