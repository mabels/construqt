class Flavour
  @parsers={}
  @renderers={}
  class << self
    attr_accessor :parsers, :renderers
  end
end
