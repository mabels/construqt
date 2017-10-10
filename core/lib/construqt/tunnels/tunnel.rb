module Construqt
  module Tunnels
    class Tunnel
      attr_reader :rights, :lefts, :transport_family
      attr_reader :name, :description
      attr_reader :delegate, :tags, :mtu_v4, :mtu_v6
      def initialize(cfg)
        @cfg = cfg
        @rights = @cfg['rights']
        @lefts = @cfg['lefts']
        (@lefts + @rights).each{ |ep| ep.tunnel = self }
        @transport_family = @cfg['transport_family']
        @name = @cfg['name']
        @description = @cfg['description']
        @mtu_v4 = @cfg['mtu_v4']
        @mtu_v6 = @cfg['mtu_v6']
        @delegate = nil
        @tags = nil
      end

      def shortname
        ['', self.ident]
      end

      def right()
        self.rights.first
      end

      def left()
        self.lefts.first
      end

      def build_config(hosts_to_process)
        # binding.pry
        (self.rights + self.lefts).each do |iface|
          # binding.pry
          iface.build_config(iface.host, iface, nil) if hosts_to_process.find{|host| iface.host.object_id == host.object_id }
        end
        [self.left.host.region, self.right.host.region].uniq.each do |region|
          region.flavour_factory.call_aspects("Tunnel.build_config", nil, self)
        end
      end

      def _ident
        "Tunnel-#{[ self.right.ident, self.left.ident ].sort.join('__')}"
      end
      def ident
        self._ident.gsub(/[^0-9a-zA-Z_]/, '_')
      end
    end
  end
end
