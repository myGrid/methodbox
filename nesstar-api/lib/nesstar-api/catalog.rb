module Nesstar
  #A Nesstar catalog object, can contain 1 or more studies (ie datasets)
  class Catalog
  
    attr_reader :studies, :label, :description, :nesstar_id
    attr_writer :studies, :label, :description, :nesstar_id
  
  end
  
end