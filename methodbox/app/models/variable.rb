require 'acts_as_solr'

class Variable < ActiveRecord::Base

  belongs_to :dataset
  has_many :variable_linkages
  has_many :variable_lists
  has_many :search_variable_lists
  has_many :csvarchives, :through => :variable_lists
  has_many :people, :through => :watched_variables
  has_many :variable_links, :through => :variable_linkages
  has_many :user_searches, :through => :search_variable_lists
  has_many :cart_items, :dependent => :destroy

  acts_as_solr(:fields=>[:name,:value,:dataset_id], :if => proc{|record| !record.is_archived?}) if SOLR_ENABLED
  
  acts_as_taggable_on :title
  acts_as_annotatable
  
  def to_param
    "#{id}-#{name.downcase.gsub(/[^[:alnum:]]/,'-')}".gsub(/-{2,}/,'-')
  end

  def hyphenName
    hyphened = name.gsub(/[a-z][A-Z][a-z]/){ |part| part.at(0) + '-' + part.at(1) + part.at(2) }
    hyphened = hyphened.gsub(/[A-Z][A-Z][a-z]/){ |part| part.at(0) + '-' + part.at(1) + part.at(2) }
    hyphened = hyphened.gsub(/[a-z][A-Z][A-Z]/){ |part| part.at(0) + '-' + part.at(1) + part.at(2) }
    return hyphened
  end
  
end
