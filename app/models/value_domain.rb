class ValueDomain < ActiveRecord::Base
  
  belongs_to :variable
  has_one :value_domain_statistic, :dependent => :destroy
  
end
