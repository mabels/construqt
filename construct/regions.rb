
module Construct
  module Regions
    @regions = {}
    class Region
      attr_reader :name, :cables, :hosts, :interfaces, :users, :vlans, :network, :templates
      def initialize(name, network)
        @name = name
        @network = network
        @vlans = Construct::Vlans.new(self)
        @hosts = Construct::Hosts.new(self)
        @interfaces = Construct::Interfaces.new(self)
        @templates = Construct::Templates.new(self)
        @users = Construct::Users.new(self)
        @cables = Construct::Cables.new(self)
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
