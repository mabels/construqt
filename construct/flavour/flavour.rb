module Construct
module Flavour
  @flavours = {}
  def self.add(flavour)
    puts "setup flavour #{flavour.name}"
    @flavours[flavour.name.downcase] = flavour
  end
  def self.find(name)
    ret = @flavours[name.downcase]
    throw "flavour #{name} not found" unless ret
    ret
  end
end
end
