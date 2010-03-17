class UserSearch < ActiveRecord::Base
  
  belongs_to :person
  
  has_many :dataset_lists

  has_many :datasets, :through => :dataset_lists
  
end