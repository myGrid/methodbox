class SearchVariableList < ActiveRecord::Base
  belongs_to :variable
  belongs_to :user_search

end