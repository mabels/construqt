module Construqt
  class Services
    class ConntrackD
      attr_accessor :name, :services
      def initialize(name)
        self.name = name
      end
    end

    class DhcpV4Relay
      attr_reader :name, :inbound_tag
      attr_accessor :services
      def initialize(name, inbound_tag)
        @name = name
        @inbound_tag = inbound_tag
      end
    end
    class DhcpV6Relay
      attr_reader :name, :inbound_tag
      attr_accessor :services
      def initialize(name, inbound_tag)
        @name = name
        @inbound_tag = inbound_tag
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
