module Construqt
  class Services

    class DhcpV4Relay
      attr_accessor :servers, :name
      def initialize(name)
        self.name = name
        self.servers = []
      end
      def add_server(ip)
        ip = IPAddress.parse(ip)
        throw "ip must be a v4 address" unless ip.ipv4?
        self.servers << ip
        self
      end
    end
    class DhcpV6Relay
      attr_accessor :servers, :name
      def initialize(name)
        self.name = name
        self.servers = []
      end
      def add_server(ip)
        ip = IPAddress.parse(ip)
        throw "ip must be a v6 address" unless ip.ipv6?
        self.servers << ip
        self
      end
    end
    class Radvd
      attr_accessor :servers, :name
      def initialize(name)
        self.name = name
      end
    end

    def initialize
      @services = {}
    end

    def find(name)
      found = @services[name]
      throw "service with name #{name} not found" unless found
      found
    end

    def add(service)
      @services[service.name] = service
      self
    end

  end
end
