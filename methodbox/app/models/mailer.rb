class Mailer < ActionMailer::Base
  helper UsersHelper

  NOREPLY_SENDER="methodbox+no-reply@googlemail.com"

  def new_message(message, base_host)
    recipients Person.find(message.to).email
    from NOREPLY_SENDER
    subject "#{Person.find(message.from).name} has sent you a message"
    sent_on    Time.now
    body :name => Person.find(message.to).name,
         :from_name => Person.find(message.from).name,
         :subject => message.subject,
         :message_id => message.id,
         :target => Person.find(message.to),
         :host=>base_host
  end

  def admin_emails
    begin
      User.admins.map { |a| a.person.email_with_name }
    rescue
      @@logger.error("Error determining admin email addresses")
      ["sowen@cs.man.ac.uk"]
    end
  end

  def request_resource(user,resource,base_host)

    subject "A MethodBox requested a protected file: #{resource.title}"
    recipients resource.contributor.person.email_with_name
    from NOREPLY_SENDER
    reply_to user.person.email_with_name
    sent_on Time.now

    body :owner=>resource.contributor.person,:requester=>user.person,:resource=>resource,:host=>base_host
  end

  def signup(user,base_host)
    subject     'MethodBox account activation'
    recipients  user.person.email_with_name
    from        NOREPLY_SENDER
    sent_on     Time.now

    body        :username=>user.email, :name=>user.person.name, :admins=>User.admins.collect{|u| u.person}, :activation_code=>user.activation_code, :host=>base_host
  end

  def signup_request_denied(user,base_host)
    subject     'MethodBox signup not possible'
    recipients  user.person.email_with_name
    from        NOREPLY_SENDER
    sent_on     Time.now

    body        :username=>user.email, :name=>user.person.name, :host=>base_host
  end

  def forgot_password(user,base_host)
    subject    'MethodBox - Password reset'
    recipients user.person.email_with_name
    from       NOREPLY_SENDER
    sent_on    Time.now

    body       :email=>user.email, :name=>user.person.name, :reset_code => user.reset_password_code, :host=>base_host
  end

  def welcome(user,base_host)
    subject    'Welcome to MethodBox'
    recipients user.person.email_with_name
    from       NOREPLY_SENDER
    sent_on    Time.now

    body       :name=>user.person.name,:person=>user.person, :host=>base_host
  end

  def contact_admin_new_user_no_profile(details,user,base_host)
    subject    'MethodBox Member signed up'
    recipients admin_emails
    from       NOREPLY_SENDER
    sent_on    Time.now

    body       :details=>details, :person=>user.person, :user=>user, :host=>base_host
  end

  def admin_created_account(admin, new_user, base_host)
    subject    'MethodBox Member created by admin'
    recipients admin_emails
    from       NOREPLY_SENDER
    sent_on    Time.now

    body       :admin=>admin, :person=>new_user.person, :host=>base_host
  end

  def signup_requested(message, new_user,base_host)
    subject    'MethodBox Signup Requested'
    recipients admin_emails
    from       NOREPLY_SENDER
    sent_on    Time.now

    body       :message=>message, :person=>new_user.person, :user=>new_user, :host=>base_host
  end
end
