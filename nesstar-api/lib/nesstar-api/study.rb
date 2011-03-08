module Nesstar
  
  #Contains a set of variables and belongs to a catalog
  class Study
  
    attr_reader :variables, :abstract, :title, :id, :dates, :sampling_procedure, :weight, :nesstar_id, :nesstar_uri
    attr_writer :variables, :abstract, :title, :id, :dates, :sampling_procedure, :weight, :nesstar_id, :nesstar_uri
  
  end
  
end