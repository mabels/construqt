
module Construqt
  class RoutingTables
    class RoutingTableAddIp
      attr_reader :ip, :options, :routing_table
      attr_accessor :attach_address
      def initialize(routing_table, ip, options)
        @routing_table = routing_table
        @ip = ip
        @options = options
      end
    end

#    class RoutingTableAddRouteFromTags
#      attr_reader :dest, :via, :options, :routing_table
#      attr_accessor :attach_address
#      def initialize(routing_table, dest, via, options)
#        @routing_table = routing_table
#        @dest = dest
#        @via = via
#        @options = options
#      end
#    end

    class RoutingTable
      attr_reader :name
      def initialize(routing_tables, name)
        @routing_table = routing_tables
        @name = name
        @add_route_from_tags_s = []
        @add_ips = []
      end

      def add_ip(ip, options = {})
        ret = RoutingTableAddIp.new(self, ip, options)
        @add_ips << ret
        ret
      end


      def add_route_from_tags(dest, via, options = {})
        ret = RoutingTableAddRouteFromTags.new(self, dest, via, options)
        @add_route_from_tags_s << ret
        ret
      end
    end

    def initialize(network)
      @network = network
      @routing_tables = {}
    end

    def create(name)
      throw "Routing table with name exists #{name}" if @routing_tables[name]
      @routing_tables[name] = RoutingTable.new(self, name)
    end

    def find(name)
      throw "Routing table with name not found #{name}" unless @routing_tables[name]
      @routing_tables[name]
    end
  end
end
