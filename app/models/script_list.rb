class ScriptList < ActiveRecord::Base
  belongs_to :script, :dependent => :destroy
  belongs_to :csvarchive, :dependent => :destroy

end