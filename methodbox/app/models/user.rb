require 'digest/sha1'
require 'acts_as_contributor'

class User < ActiveRecord::Base
  #savage_beast
  include SavageBeast::UserInit

  acts_as_contributor
  # TODO uncomment the following line when SOPs are implemented
  # has_many :sops, :as => :contributor
  
  has_many :recommendations
  
  has_many :comments
  
  has_many :links
  
  has_many :csvarchives

  belongs_to :person, :dependent => :destroy
  #validates_associated :person
  before_save :valid_person?

  #restful_authentication plugin generated code ...
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  #validates_presence_of     :login, :email - removed requirement on email
  #validates_length_of       :email,    :within => 3..100

  # validates_presence_of     :login
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?

  validates_presence_of     :email
  validates_confirmation_of :email if :email_confirmation
  validates_format_of :email,:with=>%r{^(?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i
  validates_uniqueness_of   :email, :message => "An account with this email address already exists."

  # validates_length_of       :login,    :within => 3..40

  # validates_uniqueness_of   :login, :case_sensitive => false
  before_save :encrypt_password
  before_create :make_activation_code
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :email_confirmation, :password, :password_confirmation, :last_seen_at, :last_user_activity

  has_many :favourites
  has_many :favourite_groups, :dependent => :destroy

  # can't destroy the assets, because these might be valuable even in the absence of the parent project
  has_many :assets, :as => :contributor, :dependent => :nullify

  named_scope :not_activated,:conditions=>['activated_at IS NULL'],:include=>:person
  named_scope :without_profile,:conditions=>['person_id IS NULL']
  named_scope :admins,:conditions=>['is_admin = ?',true],:include=>:person

  has_many :cart_items, :dependent => :destroy

#savage_beast
  def display_name
    if self.dormant
      "User "+id.to_s
    else
      self.person.name
    end
  end

  # #savage_beast
  #   def admin?
  #     puts "checking admin"
  #           return self.is_admin?
  #   end
  #savage_beast
  def currently_online
    false
  end

  #savage_beast
  def build_search_conditions(query)
    # query && ['LOWER(display_name) LIKE :q OR LOWER(login) LIKE :q', {:q => "%#{query}%"}]
    query
  end


  # Activates the user in the database.
  def activate
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    self.dormant = false
    self.person.dormant = false
    save(false)
    self.person.save
  end

  def active?
    # the existence of an activated at time means the use has been activated
    # the existence of an activation code means they have not activated yet but has been authorized
    activated_at
  end

  # Specifies if an account is either activated or has an activation code so it can be activated
  def approved?
    activated_at || activation_code
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find :first, :conditions => ['email = ? and activated_at IS NOT NULL', login] # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  # performs a simple conversion from an array of user's project instances into a hash { <project_id> => <project_name>, [...] }
  def generate_own_project_id_name_hash
    return Hash[*self.person.projects.collect{|p|; [p.id, p.name];}.flatten]
  end

  # returns a 'whitelist' favourite group for the user (or 'nil' if not found)
  def get_whitelist
    return FavouriteGroup.find(:first, :conditions => { :user_id => self.id, :name => FavouriteGroup::WHITELIST_NAME } )
  end

  # returns a 'blacklist' favourite group for the user (or 'nil' if not found)
  def get_blacklist
    return FavouriteGroup.find(:first, :conditions => { :user_id => self.id, :name => FavouriteGroup::BLACKLIST_NAME } )
  end

  def can_see_dormant?
    return is_admin && ADMIN_CAN_SEE_DORMANT
  end

  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

  protected
    # before filter
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    def password_required?
      crypted_password.blank? || !password.blank?
    end

    def valid_person?
      if !self.person.errors.empty?
        self.person.errors.each do |error|
          errors.add(error[0], error[1])
        end
        return false
      end
    end
end
