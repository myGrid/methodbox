class Chapter < ActiveRecord::Base
  acts_as_annotatable
  
  belongs_to :book
end