require 'acts_as_solr'

class ArchivedVariable < ActiveRecord::Base

  belongs_to :variable
  
end
