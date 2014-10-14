
module Construct
  module Regions
    @regions = {}
    class Region < OpenStruct
      def initialize(cfg)
        super(cfg)
        @vlans = Construct::Vlans.new(region)
      end
      def vlans
        @vlans
      end
    end

    def self.add(name, cfg = {})
      throw "region names #{name} has to be unique" if @regions[name]
      cfg['name'] = name
      ret = Region.new(cfg)
      @regions[name] = ret
      ret
    end
    def self.find(name)
      throw "region with name #{name} not found" unless @regions[name]
      @regions[name]
    end
  end
end
