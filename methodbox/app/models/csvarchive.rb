require 'acts_as_resource'

class Csvarchive < ActiveRecord::Base
  #really not sure about this whole acts as resource stuff yet
  acts_as_resource
  
  #based on http://blog.hasmanythrough.com/2006/4/21/self-referential-through
  # has_many :extracts_as_source, :foreign_key => 'source_id', :class_name => 'ExtractToExtractLink'
  # has_many :extracts_as_target,   :foreign_key => 'target_id',   :class_name => 'ExtractToExtractLink'
  # has_many :sources,  :through => :extracts_as_target
  # has_many :targets,    :through => :extracts_as_source

  has_many :variable_lists
  
  has_many :variables, :through => :variable_lists

  has_many :script_lists, :dependent => :destroy
  # 
  has_many :scripts, :through => :script_lists
  # 
  has_many :survey_lists, :dependent => :destroy
  # 
  has_many :surveys, :through => :survey_lists

  belongs_to :content_blob,
    :dependent => :destroy

  belongs_to :person
  
  has_many :stata_do_files

  acts_as_solr(:fields=>[:title,:description]) if SOLR_ENABLED
  
  def to_param
    "#{id}-#{title.downcase.gsub(/[^[:alnum:]]/,'-')}".gsub(/-{2,}/,'-')
  end

  def self.get_all_as_json(user)
    all_archives = Csvarchive.find(:all, :order => "ID asc")
    archives_with_contributors = all_archives.collect{ |m|
      Authorization.is_authorized?("show", nil, m, user) ?
        (p = m.asset.contributor.person;
        { "id" => m.id,
          "title" => m.title,
          "contributor" => "by " +
            (p.first_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a first name\n----\n"); "(NO FIRST NAME)") : p.first_name) + " " +
            (p.last_name.blank? ? (logger.error("\n----\nUNEXPECTED DATA: person id = #{p.id} doesn't have a last name\n----\n"); "(NO LAST NAME)") : p.last_name),
          "type" => self.name } ) :
        nil }

    archives_with_contributors.delete(nil)

    return archives_with_contributors.to_json
  end

end