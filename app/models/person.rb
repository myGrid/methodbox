require 'acts_as_editable'
# require 'grouped_pagination'

class Person < ActiveRecord::Base

  # grouped_pagination

  has_many :watched_variables

  has_many :variables, :through => :watched_variables
  has_many :variable_links
  has_many :user_searches

  acts_as_tagger

  #acts_as_annotation_source

  acts_as_editable

  #Replace these two with one below if you only want at least a first or last name
  validates_presence_of   :last_name
  validates_presence_of   :first_name
  # validates_presence_of :name

  #FIXME: consolidate these regular expressions into 1 holding class
  validates_format_of :email,:with=>%r{^(?:[_a-z0-9-]+)(\.[_a-z0-9-]+)*@([a-z0-9-]+)(\.[a-zA-Z0-9\-\.]+)*(\.[a-z]{2,4})$}i
  validates_uniqueness_of   :email
  validates_presence_of    :email

  validates_format_of :web_page, :with=>/(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix,:allow_nil=>true,:allow_blank=>true

  validates_associated :avatars

  # has_and_belongs_to_many :disciplines

  has_many :avatars,
    :as => :owner,
    :dependent => :destroy

  has_many :group_memberships

  has_many :work_groups, :through=>:group_memberships
  # has_many :roles, :through=>:group_memberships

  acts_as_taggable_on :tools, :expertise

  has_one :user, :dependent => :destroy

  #acts_as_solr(:fields => [ :first_name, :last_name,:expertise ]) if SOLR_ENABLED

  scope :without_group, :include=>:group_memberships, :conditions=>"group_memberships.person_id IS NULL"
  scope :registered,:include=>:user,:conditions=>"users.person_id != 0"
  scope :pals,:conditions=>{:is_pal=>true}

  #FIXME: change userless_people to use this scope - unit tests
  scope :not_registered,:include=>:user,:conditions=>"users.person_id IS NULL"
  
  #sunspot solr
  searchable do
    text :first_name
    text :last_name
    text :expertise
  end

  def self.userless_people
    p=Person.all
    return p.select{|person| person.user.nil?}
  end


  # get a list of people with their email for autocomplete fields
  def self.get_all_as_json
    all_people = Person.all(:order => "ID asc")
    names_emails = all_people.collect{ |p| {"id" => p.id,
        "name" => (p.first_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a first name\n----\n"); "(NO FIRST NAME)") : p.first_name) + " " +
                  (p.last_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a last name\n----\n"); "(NO LAST NAME)") : p.last_name) } }
    return names_emails.to_json
  end


  def validates_associated(*associations)
    associations.each do |association|
      class_eval do
        validates_each(associations) do |record, associate_name, value|
          associates = record.send(associate_name)
          associates = [associates] unless associates.respond_to?('each')
          associates.each do |associate|
            if associate && !associate.valid?
              associate.errors.each do |key, value|
                record.errors.add(key, value)
              end
            end
          end
        end
      end
    end
  end

  def people_i_may_know
    res=[]
    institutions.each do |i|
      i.people.each do |p|
        res << p unless p==self or res.include? p
      end
    end

    projects.each do |proj|
      proj.people.each do |p|
        res << p unless p==self or res.include? p
      end
    end
    return  res
  end

  def institutions
    res=[]
    work_groups.collect {|wg| res << wg.institution unless res.include?(wg.institution) }
    return res
  end

  def projects
    res=[]
#    work_groups.collect {|wg| res << wg.project unless res.include?(wg.project) }
    return res
  end

  def locations
    # infer all person's locations from the institutions where the person is member of
    locations = self.institutions.collect { |i| i.country unless i.country.blank? }

    # make sure this list is unique and (if any institutions didn't have a country set) that 'nil' element is deleted
    locations = locations.uniq
    locations.delete(nil)

    return locations
  end

  def email_with_name
    name + " <" + email + ">"
  end

  def name
    if dormant
      if user.activated_at
        firstname="(Dormant)"+first_name
      else
        firstname="(Awaiting Approval)"+first_name
      end
    else
      firstname=first_name
    end
    firstname||=""
    lastname=last_name
    lastname||=""
    #capitalize, including double barrelled names
    #TODO: why not just store them like this rather than processing each time? Will need to reprocess exiting entries if we do this.
    return firstname.gsub(/\b\w/) {|s| s.upcase} + " " + lastname.gsub(/\b\w/) {|s| s.upcase}
  end

  # "false" returned by this helper method won't mean that no avatars are uploaded for this person;
  # it rather means that no avatar (other than default placeholder) was selected for the person
  def avatar_selected?
    return !avatar_id.nil?
  end

end
