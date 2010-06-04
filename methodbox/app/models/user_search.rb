class UserSearch < ActiveRecord::Base
  
  belongs_to :user
  
  has_many :dataset_lists

  has_many :datasets, :through => :dataset_lists
  
  has_many :search_variable_lists
  
  has_many :variables, :through => :search_variable_lists
  
end