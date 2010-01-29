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

  def remove_variable(variable)
    puts "remove variable " + variable
    @items.delete_if{|ci| ci.to_s == variable.to_s}
    #ci.to_s == variable.to_s
#    if (@items.index(variable)!=nil)
#      puts "removing " + variable
#      @items.delete(variable)
#    end
  end
end
