class MatchedVariable < ActiveRecord::Base
  belongs_to :variable
  belongs_to :target_variable, :class_name=>"Variable", :foreign_key=>"target_variable_id"
end
