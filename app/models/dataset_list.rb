class DatasetList < ActiveRecord::Base
  belongs_to :user_search
  belongs_to :dataset
end