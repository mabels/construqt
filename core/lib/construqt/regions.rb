
module Construqt
  module Regions
    @regions = {}
    class Region
      attr_reader :name, :cables, :hosts, :interfaces, :users, :vlans, :network, :templates, :resources, :services, :registry
      def initialize(name, network, registry)
        @name = name
        @network = network
        @registry = Construqt::Registry.new(self, registry)
        @vlans = Construqt::Vlans.new(self)
        @hosts = Construqt::Hosts.new(self)
        @interfaces = Construqt::Interfaces.new(self)
        @templates = Construqt::Templates.new(self)
        @users = Construqt::Users.new(self)
        @cables = Construqt::Cables.new(self)
        @services = Construqt::Services.new(self)
        @resources = Construqt::Resources.new(self)
      end

      def get_default_group
        "admin"
      end
    end

    def self.add(name, network, registry = nil)
      throw "region names #{name} has to be unique" if @regions[name]
      ret = Region.new(name, network, registry)
      @regions[name] = ret
      ret
    end

    def self.find(name)
      throw "region with name #{name} not found" unless @regions[name]
      @regions[name]
    end
  end
end
