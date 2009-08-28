class Cart
  attr_reader :items

  def initialize
    @items= []
  end

  def add_variable(variable)
    if (@items.index(variable)==nil)
      @items << variable
    end
  end
end
