module Nesstar
  
  #Information about a variable/column in a dataset
  class Variable
  
    attr_reader :name, :label, :group, :id, :file, :interval, :max, :min, :question, :interview_instruction, :summary_stats, :categories
    attr_writer :name, :label, :group, :id, :file, :interval, :max, :min, :question, :interview_instruction, :summary_stats, :categories
      
  end
  
end