class WatchedVariable < ActiveRecord::Base
  belongs_to :person
  belongs_to :variable

end