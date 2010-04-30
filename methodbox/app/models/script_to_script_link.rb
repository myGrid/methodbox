#see http://blog.hasmanythrough.com/2006/4/21/self-referential-through
class ScriptToScriptLink < ActiveRecord::Base
  belongs_to :source, :class_name => "Script"
  belongs_to :target, :class_name => "Script"
end