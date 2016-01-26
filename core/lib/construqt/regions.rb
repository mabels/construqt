
module Construqt
  module Regions
    REGIONS = {}
    class Region
      attr_reader :name, :cables, :hosts, :interfaces, :users, :vlans, :network,
                  :templates, :resources, :services, :registry, :flavour_factory,
                  :aspects, :dns_resolver
      include Construqt::Util::Chainable
      chainable_attr_value :dest_path

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
        @flavour_factory = Construqt::Flavour::Factory.new(self)
        @dns_resolver = Construqt::Dns.new(self, network)
        @aspects = []
      end

      def get_default_group
        "admin"
      end

      def add_aspect(aspect)
        @aspects << aspect
      end

      def set_dns_resolver(nameservers, search = [])
        @dns_resolver.nameservers = nameservers
        @dns_resolver.search = search
      end

    end

    def self.add(name, network, registry = nil)
      throw "region names #{name} has to be unique" if REGIONS[name]
      ret = Region.new(name, network, registry)
      REGIONS[name] = ret
      ret
    end

    def self.find(name)
      throw "region with name #{name} not found" unless REGIONS[name]
      REGIONS[name]
    end
  end
end
