class SurveyType < ActiveRecord::Base
  
  has_many :surveys

  validates_uniqueness_of :name, :message => "There is already a survey type with this name."

  def truncated_value
    truncate(name, :length => 50, :omission => '...')
  end


end
