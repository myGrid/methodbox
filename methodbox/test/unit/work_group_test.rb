require 'test_helper'
 

class WorkGroupTest < ActiveSupport::TestCase
  
  #May 24, 2101 Commented out all test due to major reworing of work_groups model
  #def test_people
  #  wg=WorkGroup.find(1)
  #  assert_equal 2,wg.people.size
  #end
  
  #May 24, 2101 Commented out all test due to major reworing of work_groups model
  #def test_cannot_destroy_with_people
  #  wg=WorkGroup.find(1)
  #  assert !wg.people.empty?
  #  
  #  
  #  #todo how to check message?
  #  assert_raise(Exception) {wg.destroy}
  #end
  
  #May 24, 2101 Commented out all test due to major reworing of work_groups model
  #def test_can_destroy_with_no_people  
  #  wg=WorkGroup.find(1)
  #  wg.people=[]
  #  assert wg.people.empty?
  #  wg.destroy
  #end
  
  #May 24, 2101 Commented out all test due to major reworing of work_groups model
  #def test_description
  #  wg=work_groups(:one)
  #  assert_equal "Project1 at Institution1",wg.description
  #end

  def test_should_create_work_group
    assert_difference 'WorkGroup.count' do
      wg = create_work_group
      assert_equal "A Test workgroup", wg.name
      assert_equal "A bit of description", wg.info
    end
  end

  def test_nil_name_fails
    assert_no_difference 'WorkGroup.count' do
      wg = create_work_group(:name => nil)
    end
  end

  def test_duplicate_name_fails
    assert_no_difference 'WorkGroup.count' do
      wg = create_work_group(:name => "Sample Group")
    end
  end

  def test_nil_info_ok
    assert_difference 'WorkGroup.count' do
      wg = create_work_group(:info => nil)
    end
  end

  def test_nil_user_fails
    assert_no_difference 'WorkGroup.count' do
      wg = create_work_group(:user => nil)
    end
  end

#delete?

protected
  def create_work_group(options = {})
    record = WorkGroup.new({ :name => 'A Test workgroup', :info => 'A bit of description', :user => users(:work_group_owner) }.merge(options))
    record.save
    record
  end
  
end

