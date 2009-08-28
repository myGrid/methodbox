#require 'acts_as_resource'

class Csvarchive < ActiveRecord::Base
#really not sure about this whole acts as resource stuff yet
#  acts_as_resource

  has_many :variable_lists

  has_many :variables, :through => :variable_lists

  belongs_to :content_blob,
             :dependent => :destroy

  belongs_to :person

end