module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Device < OpenStruct
            include Construqt::Cables::Plugin::Single
            def initialize(cfg)
              super(cfg)
            end

            def self.add_address(host, ifname, iface, lines, writer, family)
              if iface.address.nil?
                Firewall.create(host, ifname, iface, family)
                return
              end

              writer.header.dhcpv4 if iface.address.dhcpv4?
              writer.header.dhcpv6 if iface.address.dhcpv6?
              writer.header.mode(Result::EtcNetworkInterfaces::Entry::Header::MODE_LOOPBACK) if iface.address.loopback?
              lines.add(iface.flavour) if iface.flavour
              iface.address.ips.each do |ip|
                if family.nil? ||
                    (!family.nil? && family == Construqt::Addresses::IPV6 && ip.ipv6?) ||
                    (!family.nil? && family == Construqt::Addresses::IPV4 && ip.ipv4?)
                  prefix = ip.ipv6? ? "-6 " : ""
                  lines.up("ip #{prefix}addr add #{ip.to_string} dev #{ifname}")
                  lines.down("ip #{prefix}addr del #{ip.to_string} dev #{ifname}")
                  if ip.routing_table
                    if ip.ipv4?
                      lines.up("ip #{prefix}route add #{ip.to_string} dev #{ifname} proto kernel  scope link  src #{ip.to_s} table #{ip.routing_table.name}")
                      lines.down("ip #{prefix}route del #{ip.to_string} dev #{ifname} proto kernel  scope link  src #{ip.to_s} table #{ip.routing_table.name}")
                    end

                    if ip.ipv6?
                      lines.up("ip #{prefix}route add #{ip.to_string} dev #{ifname} proto kernel table #{ip.routing_table.name}")
                      lines.down("ip #{prefix}route del #{ip.to_string} dev #{ifname} proto kernel table #{ip.routing_table.name}")
                    end

                    lines.up("ip #{prefix}rule add from #{ip.to_s} table #{ip.routing_table.name}")
                    lines.down("ip #{prefix}rule del from #{ip.to_s} table #{ip.routing_table.name}")
                  end
                end
              end

              iface.address.routes.each do |route|
                if family.nil? ||
                    (!family.nil? && family == Construqt::Addresses::IPV6 && route.via.ipv6?) ||
                    (!family.nil? && family == Construqt::Addresses::IPV4 && route.via.ipv4?)
                  metric = ""
                  metric = " metric #{route.metric}" if route.metric
                  routing_table = ""
                  routing_table = " table #{route.via.routing_table}" if route.via.routing_table
                  lines.up("ip route add #{route.dst.to_string} via #{route.via.to_s}#{metric}#{routing_table}")
                  lines.down("ip route del #{route.dst.to_string} via #{route.via.to_s}#{metric}#{routing_table}")
                end
              end

              proxy_neigh(ifname, iface, lines)
              Firewall.create(host, ifname, iface, family)
            end

            def self.proxy_neigh2ips(neigh)
              if neigh.nil?
                return []
              elsif neigh.kind_of?(Construqt::Tags::ResolverAdr) || neigh.kind_of?(Construqt::Tags::ResolverNet)
                ret = neigh.resolv()
                #puts "self.proxy_neigh2ips>>>>>#{neigh} #{ret.map{|i| i.class.name}} "
                return ret
              end

              return neigh.ips
            end

            def self.proxy_neigh(ifname, iface, lines)
              proxy_neigh2ips(iface.proxy_neigh).each do |ip|
                #puts "**********#{ip.class.name}"
                list = []
                if ip.network.to_string == ip.to_string
                  list += ip.map{|i| i}
                else
                  list << ip
                end

                list.each do |lip|
                  ipv = lip.ipv6? ? "-6 ": ""
                  lines.up("ip #{ipv}neigh add proxy #{lip.to_s} dev #{ifname}")
                  lines.down("ip #{ipv}neigh del proxy #{lip.to_s} dev #{ifname}")
                end
              end
            end

            def build_config(host, iface)
              self.class.build_config(host, iface)
            end

            def self.add_services(host, ifname, iface, writer, family)
              iface.services && iface.services.each do |service|
                Services.get_renderer(service).interfaces(host, ifname, iface, writer, family)
              end
            end

            def self.add_dhcp_client(host, ifname, iface, writer, family)
              return if iface.address.nil?
              return if !iface.address.dhcpv4?
              dhcp_client_opts = [
                "/sbin/dhclient",
                "-nw",
                "-pf /run/dhclient.#{ifname}.pid",
                "-lf /var/lib/dhcp/dhclient.#{ifname}.leases",
                "-I",
                "-df /var/lib/dhcp/dhclient6.#{ifname}.leases",
                "#{ifname}"
              ]
              writer.lines.up(dhcp_client_opts.join(" "))
              writer.lines.down("kill `cat /run/dhclient.#{ifname}.pid`")
            end

            def self.add_dhcp_server(host, ifname, iface, writer, family)
              return unless iface.dhcp
              host.result.add_component(Construqt::Resources::Component::DNSMASQ)
              dnsmasq_opts = [
                "dnsmasq",
                "-u dnsmasq",
                "--strict-order",
                "--pid-file=/run/#{ifname}-dnsmasq.pid",
                "--conf-file=",
                "--listen-address #{iface.address.first_ipv4}",
                "--domain=#{iface.dhcp.get_domain}",
                "--host-record=#{host.name}.#{iface.dhcp.get_domain}.,#{iface.address.first_ipv4}",
                "--dhcp-range #{iface.dhcp.get_start},#{iface.dhcp.get_end}",
                "--dhcp-lease-max=253",
                "--dhcp-no-override",
                "--except-interface=lo",
                "--interface=#{ifname}",
                "--dhcp-leasefile=/var/lib/misc/dnsmasq.#{ifname}.leases",
                "--dhcp-authoritative"
              ]
              writer.lines.up(dnsmasq_opts.join(" "))
              writer.lines.down("kill `cat /run/#{ifname}-dnsmasq.pid`")
            end

            def self.build_config(host, iface, ifname = nil, family = nil, mtu = nil)
              #      binding.pry
              #          if iface.dynamic
              #            Firewall.create(host, ifname||iface.name, iface, family)
              #            return
              #          end
              #binding.pry if iface.name == "border" and iface.host.name == "ao-border-wlxc4e9841f0822"
              host.result.add_component(iface.class.const_get("COMPONENT"))
              writer = host.result.etc_network_interfaces.get(iface, ifname)
              writer.header.protocol(Result::EtcNetworkInterfaces::Entry::Header::PROTO_INET4)
              writer.lines.add(iface.delegate.flavour) if iface.delegate.flavour
              ifname = ifname || writer.header.get_interface_name
              writer.lines.up("ip link set mtu #{mtu || iface.delegate.mtu} dev #{ifname} up")
              writer.lines.down("ip link set dev #{ifname} down")
              add_address(host, ifname, iface.delegate, writer.lines, writer, family)
              #binding.pry if ifname == "v202"
              add_dhcp_client(host, ifname, iface, writer, family)
              add_dhcp_server(host, ifname, iface, writer, family)
              add_services(host, ifname, iface.delegate, writer, family)
            end
          end
        end
      end
    end
  end
end
