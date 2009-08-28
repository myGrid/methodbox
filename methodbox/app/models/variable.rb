require 'acts_as_solr'

class Variable < ActiveRecord::Base

  belongs_to :survey
  has_many :csvarchives, :through => :variable_lists
  acts_as_solr(:fields=>[:name,:value]) if SOLR_ENABLED
  acts_as_taggable_on :title
  acts_as_annotatable

end
