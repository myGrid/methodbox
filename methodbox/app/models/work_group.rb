# Loose coupling of people for sharing things inside the methodbox
class WorkGroup < ActiveRecord::Base
  # No project or institutions modelled at the moment
  # belongs_to :institution
  # belongs_to :project
  has_many :group_memberships
  has_many :people, :through=>:group_memberships
  
  
  def destroy
    if people.empty?
        super
    else
      raise Exception.new("Cannot delete with associated people. This WorkGroup has "+people.size.to_s+" people associated with it")
    end
  end
  
  def description
    description
  end
  
end
