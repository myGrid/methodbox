class VariableLink < ActiveRecord::Base

  belongs_to :person
  has_many :variable_linkages
  has_many :variables, :through => :variable_linkages

end