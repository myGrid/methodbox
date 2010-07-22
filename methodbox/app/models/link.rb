# BioCatalogue: app/models/relationship.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton
# See license.txt for details


class Link < ActiveRecord::Base
  # if ENABLE_CACHE_MONEY
  #   is_cached :repository => $cache
  #   index :predicate
  #   index [ :subject_type, :subject_id ]
  #   index [ :object_type, :object_id ]
  # end
  # 
  # acts_as_trashable
  
  validates_presence_of :subject_type,
                        :subject_id, 
                        :object_type
                        :object_id
  
  validate :check_duplicate
  
  belongs_to :subject , :polymorphic => true  #e.g service
  belongs_to :object, :polymorphic => true    #e.g soaplab_server
  belongs_to :user
  
  protected

  def check_duplicate
    existing = Link.find(:all, 
                                 :conditions => { :subject_type => self.subject_type, 
                                                  :subject_id => self.subject.id,
                                                  :subject_field_name => self.subject_field_name,
                                                  :predicate => self.predicate, 
                                                  :object_type => self.object_type, 
                                                  :object_id => self.object_id,
                                                  :object_field_name => self.object_field_name })
    
    if (existing.length == 0 or existing[0].id == self.id)
      # It's all good...
      return true
    else
      self.errors.add_to_base("This Link already exists and is not allowed to be created again.")
      return false
    end
  end
end
