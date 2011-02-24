module Nesstar
  
  #Contains a set of variables and belongs to a catalog
  class Study
  
    attr_reader :variables, :abstract, :title, :id, :dates, :sampling_procedure, :weight
    attr_writer :variables, :abstract, :title, :id, :dates, :sampling_procedure, :weight
  
  end
  
end