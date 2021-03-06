# Loose coupling of people for sharing things inside the methodbox
class WorkGroup < ActiveRecord::Base
  # No project or institutions modelled at the moment
  # belongs_to :institution
  # belongs_to :project
  
  belongs_to :user
  has_many :group_memberships
  has_many :people, :through=>:group_memberships
  
  validates_presence_of     :name
  validates_uniqueness_of   :name
  
  validates_presence_of     :user
  
  def destroy
    if people.empty?
        super
    else
      raise Exception.new("Cannot delete with associated people. This WorkGroup has "+people.size.to_s+" people associated with it")
    end
  end
  
  def description
    info
  end
  
end
