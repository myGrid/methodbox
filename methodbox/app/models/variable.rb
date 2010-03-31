require 'acts_as_solr'

class Variable < ActiveRecord::Base

  belongs_to :survey
  has_many :variable_linkages
  has_many :csvarchives, :through => :variable_lists
  has_many :people, :through => :watched_variables
  has_many :variable_links, :through => :variable_linkages
  acts_as_solr(:fields=>[:name,:value,:dataset_id]) if SOLR_ENABLED
  acts_as_taggable_on :title
  acts_as_annotatable
  
  def to_param
    "#{id}-#{name.downcase.gsub(/[^[:alnum:]]/,'-')}".gsub(/-{2,}/,'-')
  end

end
