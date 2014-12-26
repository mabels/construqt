
module Construqt
  module Regions
    @regions = {}
    class Region
      attr_reader :name, :cables, :hosts, :interfaces, :users, :vlans, :network, :templates, :resources, :services
      def initialize(name, network)
        @name = name
        @network = network
        @vlans = Construqt::Vlans.new(self)
        @hosts = Construqt::Hosts.new(self)
        @interfaces = Construqt::Interfaces.new(self)
        @templates = Construqt::Templates.new(self)
        @users = Construqt::Users.new(self)
        @cables = Construqt::Cables.new(self)
        @services = Construqt::Services.new(self)
        @resources = Construqt::Resources.new(self)
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
