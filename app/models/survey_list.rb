class SurveyList < ActiveRecord::Base
  belongs_to :survey
  belongs_to :csvarchive

end