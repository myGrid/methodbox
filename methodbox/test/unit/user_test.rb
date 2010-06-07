require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase

  #Fix_me?
  #def test_without_profile
  #  without_profile=User.without_profile
  #  without_profile.each do |u|
  #    assert u.person.nil?
  #  end
  #  assert without_profile.include?(users(:part_registered))
  #  assert !without_profile.include?(users(:aaron))
  #
  #  aaron=users(:aaron)
  #  aaron.person=nil
  #  aaron.save!
  #
  #  without_profile=User.without_profile
  #  without_profile.each do |u|
  #    assert u.person.nil?
  #  end
  #  assert without_profile.include?(users(:part_registered))
  #  assert without_profile.include?(users(:normal_user))
  #end

  def test_admins_named_scope
    admins=User.admins
    assert_equal 1,admins.size
    assert admins.include?(users(:admin))
  end
  
  #This this correct?
  def test_not_activated
    not_activated=User.not_activated
    not_activated.each do |u|
      assert !u.active?
    end
    assert not_activated.include?(users(:unactivated_user))
    assert !not_activated.include?(users(:normal_user))
  end

  def test_should_create_user
    assert_difference 'User.count' do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_initialize_activation_code_upon_creation
    user = create_user
    user.reload
    assert_not_nil user.activation_code
  end

  def test_should_require_password
    assert_no_difference 'User.count' do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference 'User.count' do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference 'User.count' do
      u = create_user(:email => nil)
    end
  end

  def test_should_require_Unique_email
    assert_no_difference 'User.count' do
      u = create_user(:email => 'quentin@example.com')
    end
  end

  def test_should_reset_password
    users(:normal_user).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:normal_user), User.authenticate('aaron@example.com', 'new password')
  end

  def test_should_not_rehash_password
    users(:normal_user).update_attributes(:email => 'aaron2@example.com')
    assert_equal users(:normal_user), User.authenticate('aaron2@example.com', 'test')
  end

  def test_should_authenticate_user
    assert_equal users(:normal_user), User.authenticate('aaron@example.com', 'test')
  end

  def test_should_set_remember_token
    users(:normal_user).remember_me
    assert_not_nil users(:normal_user).remember_token
    assert_not_nil users(:normal_user).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:normal_user).remember_me
    assert_not_nil users(:normal_user).remember_token
    users(:normal_user).forget_me
    assert_nil users(:normal_user).remember_token
  end

  def test_should_remember_me_for_one_week
    before = 1.week.from_now.utc
    users(:normal_user).remember_me_for 1.week
    after = 1.week.from_now.utc
    assert_not_nil users(:normal_user).remember_token
    assert_not_nil users(:normal_user).remember_token_expires_at
    assert users(:normal_user).remember_token_expires_at.between?(before, after)
  end

  def test_should_remember_me_until_one_week
    time = 1.week.from_now.utc
    users(:normal_user).remember_me_until time
    assert_not_nil users(:normal_user).remember_token
    assert_not_nil users(:normal_user).remember_token_expires_at
    assert_equal users(:normal_user).remember_token_expires_at, time
  end

  def test_should_remember_me_default_two_weeks
    before = 2.weeks.from_now.utc
    users(:normal_user).remember_me
    after = 2.weeks.from_now.utc
    assert_not_nil users(:normal_user).remember_token
    assert_not_nil users(:normal_user).remember_token_expires_at
    assert users(:normal_user).remember_token_expires_at.between?(before, after)
  end

protected
  def create_user(options = {})
    record = User.new({ :email => 'micheal@example.com', :password => 'testPass', :password_confirmation => 'testPass' }.merge(options))
    record.save
    record
  end
end
