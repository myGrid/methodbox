require 'acts_as_resource'

class Script < ActiveRecord::Base

  acts_as_resource
  
  has_many :notes, :as => :notable
  
  has_many :recommendations, :as => :recommendable
  
  has_many :comments, :as => :commentable

  has_many :script_lists

  has_many :csvarchives, :through => :script_lists

  has_many :survey_to_script_lists

  has_many :surveys, :through => :survey_to_script_lists

  validates_presence_of :title, :message => "error - you must provide a title."

  # allow same titles, but only if these belong to different users
  validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type ], :message => "error - you already have a Script with such title."

  validates_presence_of :original_filename, :message => "error - original_filename missing."

  belongs_to :content_blob,
             :dependent => :destroy

  belongs_to :person, :dependent => :destroy
  
  #sunspot solr
  searchable do
    text :description
    text :title
  end

  def to_param
    "#{id}-#{title.downcase.gsub(/[^[:alnum:]]/,'-')}".gsub(/-{2,}/,'-')
  end

    def self.get_all_as_json(user)
    all_scripts = Script.find(:all, :order => "ID asc")
    scripts_with_contributors = all_scripts.collect{ |m|
        Authorization.is_authorized?("show", nil, m, user) ?
        (p = m.asset.contributor.person;
        { "id" => m.id,
          "title" => m.title,
          "contributor" => "by " +
                           (p.first_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a first name\n----\n"); "(NO FIRST NAME)") : p.first_name) + " " +
                           (p.last_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a last name\n----\n"); "(NO LAST NAME)") : p.last_name),
          "type" => self.name } ) :
        nil }

    scripts_with_contributors.delete(nil)

    return scripts_with_contributors.to_json
  end

end
