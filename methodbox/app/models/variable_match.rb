class VariableMatch < ActiveRecord::Base

has_many :matched_variable_lists

belongs_to :source_variable, :class_name => "Variable" 
  
has_many :target_variables, :through => :matched_variable_lists, :class_name => "Variable"

end
