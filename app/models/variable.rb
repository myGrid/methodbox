#require 'acts_as_solr'

class Variable < ActiveRecord::Base
  
  has_many :notes, :as => :notable
  
  has_many :comments, :as => :commentable

  belongs_to :dataset
  has_many :variable_linkages
  has_many :variable_lists
  has_many :search_variable_lists
  has_many :csvarchives, :through => :variable_lists
  has_many :people, :through => :watched_variables
  has_many :variable_links, :through => :variable_linkages
  has_many :user_searches, :through => :search_variable_lists
  has_many :cart_items, :dependent => :destroy
  has_many :value_domains, :dependent => :destroy
  has_many :matched_variables
  has_many :target_variables, :through => :matched_variables, :class_name => "Variable" 

  #acts_as_solr(:fields=>[:name, :value, :dataset_id], :if => proc{|record| !record.is_archived?}) if SOLR_ENABLED
  
  acts_as_taggable_on :title
  acts_as_annotatable
  
  #sunspot solr
  searchable do
    text :name
    text :value
    integer :dataset_id
    text :values do
      value_domains.map { |value_domain|  value_domain.label }
    end
  end
  
  def to_param
    "#{id}-#{name.downcase.gsub(/[^[:alnum:]]/,'-')}".gsub(/-{2,}/,'-')
  end

  def hyphenName
    hyphened = name.gsub(/[a-z][A-Z][a-z]/){ |part| part.at(0) + '-' + part.at(1) + part.at(2) }
    hyphened = hyphened.gsub(/[A-Z][A-Z][a-z]/){ |part| part.at(0) + '-' + part.at(1) + part.at(2) }
    hyphened = hyphened.gsub(/[a-z][A-Z][A-Z]/){ |part| part.at(0) + '-' + part.at(1) + part.at(2) }
    return hyphened
  end
  
  #If the variable is an MB native one then read the stats from file
  def none_values_hash
    begin
    hash = Hash.new(0)  
    if !self.nesstar_id
      #hash["path"]= self.none_values_distribution_file
      #arr = self.none_values_distribution_file.split("/")
      #index = arr.size - 2
      file = File.open(File.join(CSV_FILE_PATH, self.dataset.uuid_filename.split('.')[0], self.name.downcase + ".csv"), "r")
      #hash["file"] = file.to_s
      file.each_line do |line|
        parts = line.split(",")  
        frequency = Integer(parts[parts.size - 1])
        #might be commas in the value so remove the frequency from the line using gsub
        hash[line.gsub("," + parts[parts.size - 1], "")] = frequency 
      end  
      file.close()
    end
    #hash["test"]="success"
    #hash["more"]="yep"
    return hash
    rescue Exception => e
      logger.error("Could not open stats file for variable " + self.id.to_s + ". " + e)
      return Hash.new(0)
    end
  end
  
  #If the variable is an MB native one then read the stats from file
  def values_hash
    begin
    hash = Hash.new(0)  
    if !self.nesstar_id
      #arr = self.values_distribution_file.split("/")
      #index = arr.size - 2
      file = File.open(File.join(CSV_FILE_PATH, self.dataset.uuid_filename.split('.')[0], self.name.downcase + ".data"), "r")
      file.each_line do |line|
        parts = line.split(",")	      
        value = Float(parts[0])
        frequency = Integer(parts[parts.size - 1])
        #might be commas in the value so remove the frequency from the line using gsub
        hash[line.gsub("," + parts[parts.size - 1], "")] = frequency

      end  
    end
    return hash
    rescue Exception => e
      logger.error("Could not open stats file for variable " + self.id.to_s + ". " + e)
      return Hash.new(0)
    end
  end

end
