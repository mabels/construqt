module Construqt
  class Services
    class ConntrackD
      attr_accessor :name, :services
      def initialize(name)
        self.name = name
      end
    end

    class DhcpV4Relay
      attr_accessor :servers, :name, :services
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
      attr_accessor :servers, :name, :services
      def initialize(name)
        self.name = name
        self.servers = []
      end
      class Server
        attr_accessor :ip, :iface
      end
      def add_server(name)
        (ip, iface) = name.split("%")
        throw "ip not set #{name}" unless ip
        ip = IPAddress.parse(ip)
        throw "ip must be a v6 address" unless ip.ipv6?
        throw "iface not set #{name}" if iface.nil? || iface.empty?
        server = Server.new
        server.ip = ip
        server.iface = iface
        self.servers << server
        self
      end
    end
    class Radvd
      attr_accessor :servers, :name, :services
      def initialize(name)
        self.name = name
      end
    end


    attr_reader :region
    def initialize(region)
      @region = region
      @services = {}
    end

    def find(name)
      found = @services[name]
      throw "service with name #{name} not found" unless found
      found
    end

    def add(service)
      @services[service.name] = service
      service.services = self
      self
    end

  end
end
