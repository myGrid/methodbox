class SurveyToScriptList < ActiveRecord::Base
  belongs_to :survey
  belongs_to :script

end