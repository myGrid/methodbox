class Dataset < ActiveRecord::Base

  belongs_to :survey

  has_many :variables
  
  has_many :dataset_lists

  has_many :user_searches, :through => :dataset_lists
  
  def to_param
    "#{id}-#{name.downcase.gsub(/[^[:alnum:]]/,'-')}".gsub(/-{2,}/,'-')
  end

end