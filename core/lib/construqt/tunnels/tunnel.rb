module Construqt
  module Tunnels
    class Tunnel
      attr_reader :transport_family, :left_endpoint, :right_endpoint
      attr_reader :name, :description, :services
      attr_reader :delegate, :tags, :mtu_v4, :mtu_v6
      # attr_reader :tunnel
      def initialize(cfg)
        @cfg = cfg
        # @tunnel = true # this is a tunnel
        # @rights = @cfg['rights']
        # @lefts = @cfg['lefts']
        # (@lefts + @rights).each{ |ep| ep.tunnel = self }
        throw "tunnel need left" unless cfg['left']
        throw "tunnel need right" unless cfg['right']
        @transport_family = @cfg['transport_family']
        @name = @cfg['name']
        @description = @cfg['description']
        @mtu_v4 = @cfg['mtu_v4']
        @mtu_v6 = @cfg['mtu_v6']
        @services = Services.create(cfg['services'])
        @left_endpoint = Endpoint.new(self, cfg['left'])
        service_attach_endpoint('left', @left_endpoint)
        @right_endpoint = Endpoint.new(self, cfg['right'])
        service_attach_endpoint('right', @right_endpoint)
      end

      def shortname
        ['', self.ident]
      end

      def service_attach_endpoint(direction, endpoint)
        @services.map do |srv|
          if srv.respond_to?(:attach_endpoint) || nil
            endpoint.services.add(srv.attach_endpoint(direction, endpoint))
          end
        end.compact
      end


      def endpoints()
        [self.left_endpoint, self.right_endpoint]
      end

      def build_config(hosts_to_process)
        # binding.pry
        self.endpoints.each do |iface|
          # binding.pry
          iface.build_config(iface.host, iface, nil) if hosts_to_process.find{|host| iface.host.object_id == host.object_id }
        end
        self.endpoints.map{|ep| ep.host.region }.uniq.each do |region|
          region.flavour_factory.call_aspects("Tunnel.build_config", nil, self)
        end
      end

      def _ident
        # binding.pry
        "Tunnel-#{self.endpoints.map{|i| i.name}.sort.join('__')}"
      end
      def ident
        self._ident.gsub(/[^0-9a-zA-Z_]/, '_')
      end
    end
  end
end
