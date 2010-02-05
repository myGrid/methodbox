class Dataset < ActiveRecord::Base

  belongs_to :survey

  has_many :variables

end