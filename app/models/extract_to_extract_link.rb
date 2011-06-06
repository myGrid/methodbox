#see http://blog.hasmanythrough.com/2006/4/21/self-referential-through
class ExtractToExtractLink < ActiveRecord::Base
  belongs_to :source, :class_name => "Csvarchive"
  belongs_to :target, :class_name => "Csvarchive"
end