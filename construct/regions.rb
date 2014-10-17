
module Construct
  module Regions
    @regions = {}
    class Region
      def initialize(name, network)
        @name = name
        @network = network
        @vlans = Construct::Vlans.new(self)
        @hosts = Construct::Hosts.new(self)
        @interfaces = Construct::Interfaces.new(self)
        @templates = Construct::Templates.new(self)
        @users = Construct::Users.new(self)
      end
      def name
        @name
      end
      def hosts
        @hosts
      end
      def interfaces
        @interfaces
      end
      def users
        @users
      end
      def vlans
        @vlans
      end
      def network
        @network
      end
      def templates
        @templates
      end
    end

    def self.add(name, network)
      throw "region names #{name} has to be unique" if @regions[name]
      ret = Region.new(name, network)
      @regions[name] = ret
      ret
    end
    def self.find(name)
      throw "region with name #{name} not found" unless @regions[name]
      @regions[name]
    end
  end
end
