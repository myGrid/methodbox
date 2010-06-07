require 'test_helper'

class MailerTest < ActionMailer::TestCase
  fixtures :all


  def setup
     @expected.from    = "methodbox+no-reply@googlemail.com"
  end
  
  test "signup" do
    @expected.subject = 'MethodBox account activation'
    @expected.to = "Not_Yet Activated <unactivated@example.com>"
    @expected.date    = Time.now

    @expected.body    = read_fixture('signup')
    
    check_email @expected, Mailer.create_signup(users(:unactivated_user),"localhost")
  end

  #May 24, 2010 Pictures no longer in data_files
  #test "request resource" do
  #  @expected.subject = "A MethodBox Member requested a protected file: Picture"
  #  @expected.to = "Datafile Owner <data_file_owner@email.com>"
  #  @expected.from = "no-reply@sysmo-db.org"
  #  @expected.reply_to = "Aaron Spiggle <aaron@email.com>"
  #  @expected.date = Time.now
  #
  #  @expected.body = read_fixture('request_resource')

  #  resource=data_files(:picture)
  #  user=users(:aaron)
  #  check_email @expected, Mailer.create_request_resource(user,resource,"localhost")
  #end

  test "forgot_password" do
    @expected.subject = 'MethodBox - Password reset'
    @expected.to = "Aaron Spiggle <aaron@example.com>"
    @expected.date    = Time.now

    @expected.body    = read_fixture('forgot_password')
    
    u=users(:normal_user)
    u.reset_password_code_until = 1.day.from_now
    u.reset_password_code="someCode"
    check_email @expected, Mailer.create_forgot_password(users(:normal_user),"localhost")
  end

  test "contact_admin_new_user_no_profile" do
    @expected.subject = 'MethodBox Member signed up'
    @expected.to = "Quentin Jones <quentin@email.com>"
    @expected.date    = Time.now

    @expected.body    = read_fixture('contact_admin_new_user_no_profile')
    
    check_email @expected, Mailer.create_contact_admin_new_user_no_profile("test message",users(:unactivated_user),"localhost")
  end

  test "welcome" do
    @expected.subject = 'Welcome to MethodBox'
    @expected.to = "Aaron Spiggle <aaron@example.com>"
    @expected.from    = "methodbox+no-reply@googlemail.com"
    @expected.date = Time.now  
    @expected.body = read_fixture('welcome')
    
    check_email @expected, Mailer.create_welcome(users(:normal_user),"localhost")
  end

  def check_email(expected, response)
    assert_equal expected.subject, response.subject
    assert_equal expected.to,      response.to
    assert_equal expected.from,    response.from
    assert_equal expected.date,    response.date
    
    expected_body = expected.body.split("\n")
    response_body = response.body.split("\n")
    
    for i in 0..(expected_body.length-1)
      #puts expected_body[i]
      #puts response_body[i]
      assert_equal expected_body[i], response_body[i]
    end  
    #puts " "
    assert_equal expected.body, response.body
    assert_equal expected.encoded, response.encoded
  end
end
