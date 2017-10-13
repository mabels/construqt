module Construqt
  module Tunnels
    class Endpoint
      attr_accessor :remote
      attr_reader :tunnel, :description
      attr_reader :host, :local, :address, :endpoint_address, :name
      attr_reader :firewalls, :interfaces, :services
      def initialize(tunnel, cfg, endpoint_service_factory)
        # binding.pry
        @tunnel = tunnel
        throw "endpoint_address missing" unless cfg['endpoint_address'].valid?
        throw "address missing" unless cfg['address']
        throw "host missing" unless cfg['host']
        # throw "tunnel missing" unless cfg['tunnel']
        # throw "my not found #{cfg.keys.inspect}" unless cfg['my']
        # throw "host not found #{cfg.keys.inspect}" unless cfg['host']
        # throw "remote not found #{cfg.keys.inspect}" unless cfg['remote']
        # binding.pry if cfg['host'].name.start_with?("na-ct-r0")
        @host = cfg['host']
        @local = self
        @firewalls = cfg['firewalls'] || []
        @interfaces = cfg['interfaces'] || []
        #@tunnel = cfg['tunnel']
        @address = cfg['address']
        @endpoint_address = cfg['endpoint_address']
        @description = cfg['description'] || "endpoint on #{host.name} for tunnel #{@tunnel.name}"
        if cfg['name'] && !cfg['name'].empty?
          @name = cfg['name']
        else
          @name = "Endpoint-#{host.name}-#{tunnel.name}"
        end
        @services = Services.create((cfg['services'] || []) + endpoint_service_factory)
      end

      def _ident
        "Endpoint-#{host.name}-#{tunnel.name}"
      end

      def ident
        self._ident.gsub(/[^0-9a-zA-Z_]/, '_')
      end

      def get_prepare()
        prepare = { }
        if self.tunnel.transport_family.nil? || self.tunnel.transport_family == Construqt::Addresses::IPV6
          remote = self.remote.endpoint_address.get_address_ipv6
          mode_v6 = "ip6gre"
          mode_v4 = "ipip6"
          transport_family = Construqt::Addresses::IPV6
          prefix = 6
        else
          remote = self.remote.endpoint_address.get_address_ipv4
          mode_v6 = "sit"
          mode_v4 = "gre"
          transport_family = Construqt::Addresses::IPV4
          prefix = 4
        end

        #binding.pry
        if self.local.address.first_ipv6
          prepare[6] = OpenStruct.new(:gt => "gt6", :prefix=>prefix, :family => Construqt::Addresses::IPV6,
                                      :my => self.local,
                                      :gre => self,
                                      :transport_family => transport_family,
                                      :other => self.remote, #.interface.delegate.local,
                                      :remote => remote, :mode => mode_v6,
                                      :mtu => self.tunnel.mtu_v6 || 1460)
        end
        if self.local.address.first_ipv4
          prepare[4] = OpenStruct.new(:gt => "gt4", :prefix=>prefix, :family => Construqt::Addresses::IPV4,
                                      :my=>self.local,
                                      :gre => self,
                                      :transport_family => transport_family,
                                      :other => self.remote, #.interface.delegate.local,
                                      :remote => remote, :mode => mode_v4,
                                      :mtu => self.tunnel.mtu_v4 || 1476)
        end
        throw "need a local address #{host.name}:#{self.tunnel.name}" if prepare.empty?
        prepare
      end

      def create_interfaces
        prepare = self.get_prepare()
        prepare.values.map do |cfg|
          iname = "#{cfg.gt}-#{self.local.host.name}--#{self.remote.host.name}"
          # Util.clean_if(cfg.gt, self.tunnel.name)
          ips = self.local.endpoint_address.get_address.by_family(cfg[:transport_family])
          local_iface = host.interfaces.values.find do |iface|
            iface.address && ips.find{ |i| iface.address.match_network(i) }
          end
          throw "need a interface with address #{host.name}:#{cfg.remote.ipaddr}" unless local_iface
          # binding.pry if iname == "gt4rtwlmgt"
          #binding.pry
          addrs = host.region.network.addresses.create
          cfg.my.address.by_family(cfg.family).map do |adr|
            addrs.add_ip(adr.to_string)
          end
          cfg.my.address.routes.each do |rt|
            if cfg.family == Construqt::Addresses::IPV4 && rt.dst.ipv4? ||
               cfg.family == Construqt::Addresses::IPV6 && rt.dst.ipv6?
              addrs.add_route(rt.dst.to_string, rt.via.to_s, rt.options)
            end
          end
          # binding.pry
          self.interfaces << host.region.interfaces.add_device(host, iname,
            "address" => addrs,
            "mtu" => cfg.mtu,
            "description" => "tunnel endpoint for #{cfg.transport_family}",
            # "name_prefix" => cfg.gt,
            # "connection_name" => "#{self.local.host.name}--#{self.remote.host.name}",
            "interfaces" => [local_iface],
            "firewalls" => self.firewalls.map{|i| i.name},
            "services" => self.services.map{|i| i},
            "endpoint" => self,
            "name_prefix" => cfg.gt,
            "mode" => cfg.mode,
            "cfg" => cfg,
            "clazz" => "gre")
            # binding.pry
          # binding.pry # if host.name == "iscaac"
          # local_iface.add_child(gt)
          # gt.add_child(local_iface)
          # local_iface.add_child(gt)
          # gt.add_child(local_iface)
          # gt.add_child(gre_delegate)
          # binding.pry

          # local_ifaces[local_iface.name] ||= OpenStruct.new(:iface => local_iface, :inames => [])
          # local_ifaces[local_iface.name].inames << iname

          #writer = host.result.etc_network_interfaces.get(gre, iname)
          #writer.skip_interfaces.header.interface_name(iname)
          #writer.lines.up("ip -#{cfg.prefix} tunnel add #{iname} mode #{cfg.mode} local #{cfg.my.to_s} remote #{cfg.other.to_s}")
          #Device.build_config(host, gre, node, iname, cfg.family, cfg.mtu)
          #writer.lines.down("ip -#{cfg.prefix} tunnel del #{iname}")
        end

        def build_config(host, iface, _)
          # binding.pry
          host.region.flavour_factory.call_aspects("Endpoint.build_config", nil, self)
        end

      end

    end
  end
end
