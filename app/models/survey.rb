require 'acts_as_resource'

class Survey < ActiveRecord::Base

  acts_as_resource

  has_many :topics, :as => :topicable
  
  belongs_to :survey_type
  
  belongs_to :survey
  
  has_many :surveys
  
  has_many :notes, :as => :notable
  
  has_many :comments, :as => :commentable

  has_many :datasets

  has_many :survey_lists
  # 
  has_many :csvarchives, :through => :survey_lists
  # 
  has_many :survey_to_script_lists
  # 
  has_many :scripts, :through => :survey_to_script_lists
  
  #acts_as_solr(:fields=>[:description,:title,:year]) if SOLR_ENABLED

#  belongs_to :content_blob,
#             :dependent => :destroy
  
    validates_uniqueness_of :title, :scope => [ :contributor_id, :contributor_type, :survey_type_id ], :message => "error - you already have a Survey with such a title."

    #sunspot solr
    searchable do
      integer :id
      text :description
      text :title
      text :year
      string :title
    end
    def to_param
      "#{id}-#{title.downcase.gsub(/[^[:alnum:]]/,'-')}".gsub(/-{2,}/,'-')
    end
    
  # get a list of Surveys with their original uploaders - for autocomplete fields
  # (authorization is done immediately to save from iterating through the collection again afterwards)
  #
  # Parameters:
  # - user - user that performs the action; this is required for authorization
  def self.get_all_as_json(user)
    all_surveys = Survey.find(:all, :order => "ID asc")
    surveys_with_contributors = all_surveys.collect{ |d|
        Authorization.is_authorized?("show", nil, d, user) ?
        (p = d.asset.contributor.person;
        { "id" => d.id,
          "title" => d.title,
          "contributor" => "by " +
                           (p.first_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a first name\n----\n"); "(NO FIRST NAME)") : p.first_name) + " " +
                           (p.last_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a last name\n----\n"); "(NO LAST NAME)") : p.last_name),
          "type" => self.name } ) :
        nil }

    surveys_with_contributors.delete(nil)

    return surveys_with_contributors.to_json
  end
end
