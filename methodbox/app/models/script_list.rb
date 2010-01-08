class ScriptList < ActiveRecord::Base
  belongs_to :script
  belongs_to :csvarchive

end