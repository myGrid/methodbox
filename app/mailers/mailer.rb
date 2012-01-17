class Mailer < ActionMailer::Base
  helper UsersHelper

  NOREPLY_SENDER="methodbox+no-reply@googlemail.com"
  
  def nesstar_catalogs_processing_error(dataset, user_id, error, base_host)
    recipients User.find(user_id).person.email
    from NOREPLY_SENDER
    subject "Problem processing nesstar catalogs"
    sent_on    Time.now
    body :name => User.find(user_id).person.name,
         :error => error,
         :host=>base_host
  end
  
  def nesstar_catalogs_processed(datasets, user_id, base_host)
    recipients User.find(user_id).person.email
    from NOREPLY_SENDER
    subject "Nesstar Catalogs Processed"
    sent_on    Time.now
    body :name => User.find(user_id).person.name,
         :host=>base_host
  end
  
  def metadata_processing_error(dataset_id, user_id, error, base_host)
    recipients User.find(user_id).person.email
    from NOREPLY_SENDER
    subject "Problem processing metadata for dataset " + Dataset.find(dataset_id).name
    sent_on    Time.now
    body :name => User.find(user_id).person.name,
         :dataset => Dataset.find(dataset_id),
         :error => error,
         :host=>base_host
  end
  
  def metadata_processed(dataset_id, user_id, base_host)
    recipients User.find(user_id).person.email
    from NOREPLY_SENDER
    subject "Metadta processed for dataset " + Dataset.find(dataset_id).name
    sent_on    Time.now
    body :name => User.find(user_id).person.name,
         :dataset => Dataset.find(dataset_id),
         :host=>base_host
  end
  
  def shibboleth_signup(user,base_host)
    subject     'MethodBox account activation'
    recipients  user.person.email_with_name
    from        NOREPLY_SENDER
    sent_on     Time.now

    body        :username=>user.email, :name=>user.person.name, :admins=>User.admins.collect{|u| u.person}, :activation_code=>user.activation_code, :host=>base_host
  end
  
  def dataset_processing_error(dataset_id, user_id, base_host)
    recipients User.find(user_id).person.email
    from NOREPLY_SENDER
    subject "Problem processing dataset " + Dataset.find(dataset_id).name
    sent_on    Time.now
    body :name => User.find(user_id).person.name,
         :dataset => Dataset.find(dataset_id),
         :host=>base_host
  end
  
  def dataset_processed(dataset_id, user_id, base_host)
    recipients User.find(user_id).person.email
    from NOREPLY_SENDER
    subject "Dataset " + Dataset.find(dataset_id).name + " ready"
    sent_on    Time.now
    body :name => User.find(user_id).person.name,
         :dataset => Dataset.find(dataset_id),
         :host=>base_host
  end
  
  def data_extract_failed(data_extract_id, user_id, error, base_host)
    recipients User.find(user_id).person.email
    from NOREPLY_SENDER
    subject "Data Extract " + Csvarchive.find(data_extract_id).title + " creation failed"
    sent_on    Time.now
    body :name => User.find(user_id).person.name,
         :data_extract => Csvarchive.find(data_extract_id),
         :error => error,
         :host=>base_host
  end
  
  def data_extract_complete(data_extract_id, user_id, base_host)
    recipients User.find(user_id).person.email
    from NOREPLY_SENDER
    subject "Data Extract " + Csvarchive.find(data_extract_id).title + " ready"
    sent_on    Time.now
    body :name => User.find(user_id).person.name,
         :data_extract => Csvarchive.find(data_extract_id),
         :host=>base_host
  end

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
         :host=>base_host,
         :message => message.body
  end
  
  def work_group_request(message, base_host)
    recipients Person.find(message.to).email
    from NOREPLY_SENDER
    subject "#{Person.find(message.from).name} has requested access to your group"
    sent_on    Time.now
    puts " message is " + message.body
    body :name => Person.find(message.to).name,
         :from_name => Person.find(message.from).name,
         :subject => message.subject,
         :message_id => message.id,
         :target => Person.find(message.to),
         :host=>base_host,
         :message => message.body
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
