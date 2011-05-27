class MatchedVariableList < ActiveRecord::Base
  belongs_to :variable_match
  belongs_to :target_variable ,:class_name=>"variable"
end
