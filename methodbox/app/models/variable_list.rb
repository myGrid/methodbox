class VariableList < ActiveRecord::Base
  belongs_to :variable
  belongs_to :csvarchive, :dependent => :destroy

end