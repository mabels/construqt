

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            class UpDownerDebianTaste
              attr_reader :dispatch
              attr_reader :etc_network_interfaces, :etc_network_iptables, :etc_conntrackd_conntrackd

              attr_reader :result

              def result=(result)
                @result = result
                @etc_network_interfaces = EtcNetworkInterfaces.new(result)
                @etc_conntrackd_conntrackd = EtcConntrackdConntrackd.new(result)
              end
              def initialize()
                @etc_network_vrrp = EtcNetworkVrrp.new
                cp = Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::UpDown
                @dispatch = {
                    cp::Device.name => lambda {|i, u| render_device(i, u) },
                    cp::Bgp.name => lambda {|i, u| render_bgp(i, u) },
                    cp::DhcpV4.name => lambda {|i, u| render_dhcp_v4(i, u) },
                    cp::DnsMasq.name => lambda {|i, u| render_dns_masq(i, u) },
                    cp::OpenVpn.name => lambda {|i, u| render_open_vpn(i, u) },
                    cp::Bridge.name => lambda {|i, u| render_bridge(i, u) },
                    cp::IpAddr.name => lambda {|i, u| render_ip_addr(i, u) },
                    cp::IpSecConnect.name => lambda {|i, u| render_ip_sec_connect(i, u) },
                    cp::BridgeMember.name => lambda {|i, u| render_bridge_member(i, u) },
                    cp::DhcpV6.name => lambda {|i, u| render_dhcp_v6(i, u) },
                    cp::IpProxyNeigh.name => lambda {|i, u| render_ip_proxy_neigh(i, u) },
                    cp::LinkMtuUpDown.name => lambda {|i, u| render_link_mtu_up_down(i, u) },
                    cp::Tunnel.name => lambda {|i, u| render_tunnel(i, u) },
                    cp::DhcpClient.name => lambda {|i, u| render_dhcp_client(i, u) },
                    cp::IpRoute.name => lambda {|i, u| render_ip_route(i, u) },
                    cp::Loopback.name => lambda {|i, u| render_loopback(i, u) },
                    cp::Vlan.name => lambda {|i, u| render_vlan(i, u) },
                    cp::Wlan.name => lambda {|i, u| render_wlan(i, u) },
                    cp::IpTables.name => lambda {|i, u| render_iptables(i, u) }
                }
                # binding.pry
              end

              def commit
                result.add(EtcNetworkInterfaces, etc_network_interfaces.commit,
                  Construqt::Resources::Rights.root_0644,
                  'etc', 'network', 'interfaces')
                @etc_network_vrrp.commit(result)
                result.ipsec_secret.commit
                result.ipsec_cert_store.commit
              end

              def render_iptables(iface, u)
                writer = etc_network_interfaces.get(iface)
                writer.lines.up("/sbin/iptables-restore /etc/network/iptables.cfg")
                writer.lines.up("/sbin/ip6tables-restore /etc/network/ip6tables.cfg")
              end

              def render_device(iface, ud)
                writer = etc_network_interfaces.get(iface, ud.ifname)
                writer.header.protocol(Result::EtcNetworkInterfaces::Entry::Header::PROTO_INET4)
                writer.lines.add(iface.delegate.flavour) if iface.delegate.flavour
              end

              def render_bgp(i, u)
                throw "unimplemented"
                writer.lines.up("/usr/sbin/#{cmd} enable #{cname}", 2000, :extra)
                writer.lines.down("/usr/sbin/#{cmd} disable #{cname}", -2000, :extra)
              end
              def render_dhcp_v4(iface, u)
                writer = etc_network_interfaces.get(iface)
                writer.header.dhcpv4
              end
              def render_dhcp_v6(iface, u)
                writer = etc_network_interfaces.get(iface)
                writer.header.dhcpv6
              end

              def render_open_vpn(iface, u)
                writer = etc_network_interfaces.get(iface)
                writer.lines.up("mkdir -p /dev/net", :extra)
                writer.lines.up("mknod /dev/net/tun c 10 200", :extra)
                writer.lines.up("/usr/sbin/openvpn --config /etc/openvpn/#{iface.name}.conf", :extra)
                writer.lines.down("kill $(cat /run/openvpn.#{iface.name}.pid)", :extra)
              end
              def render_bridge(iface, ud)
                etc_network_interfaces.get(iface).lines.add("bridge_ports none", 0)
              end
              def render_ip_sec_connect(iface, ud)
                writer = etc_network_interfaces.get(iface, iface.name)
                writer.lines.up("/usr/sbin/ipsec start", :extra) # no down this is also global
                writer.lines.up("/usr/sbin/ipsec up #{ud.name} &", 1000, :extra)
                writer.lines.down("/usr/sbin/ipsec down #{ud.name} &", -1000, :extra)
              end
              def render_bridge_member(iface, ud)
                writer = etc_network_interfaces.get(iface, ud.ifname)
                writer.lines.up "brctl addif #{ud.bname} #{ud.ifname}"
                writer.lines.down "brctl delif #{ud.bname} #{ud.ifname}"
              end
              def render_ip_proxy_neigh(iface, ud)
                writer = etc_network_interfaces.get(iface, ud.ifname)
                ipv = ud.ip.ipv6? ? "-6 ": "-4 "
                writer.lines.up("ip #{ipv}neigh add proxy #{ud.ip.to_s} dev #{ud.ifname}", :extra)
                writer.lines.down("ip #{ipv}neigh del proxy #{ud.ip.to_s} dev #{ud.ifname}", :extra)
              end
              def render_link_mtu_up_down(iface, ud)
                writer = etc_network_interfaces.get(iface, ud.ifname)
                writer.lines.up("ip link set mtu #{ud.mtu} dev #{ud.ifname} up")
                writer.lines.down("ip link set dev #{ud.ifname} down")
              end
              def render_tunnel(iface, ud)
                writer = etc_network_interfaces.get(iface, iface.name)
                writer.lines.up("ip -#{ud.cfg.prefix} tunnel add #{iface.name} mode #{ud.cfg.mode} local #{ud.local} remote #{ud.remote}")
                writer.lines.down("ip -#{ud.cfg.prefix} tunnel del #{iface.name}")
              end
              def render_vlan(iface, ud)
              end
              def render_loopback(iface, ud)
                writer = etc_network_interfaces.get(iface, iface.name)
                writer.header.mode(Result::EtcNetworkInterfaces::Entry::Header::MODE_LOOPBACK) if iface.address.loopback?
              end
              def render_ip_addr(iface, ud)
                writer = etc_network_interfaces.get(iface, ud.ifname)
                prefix = ud.ip.ipv6? ? "-6 " : "-4 "
                writer.lines.up("ip #{prefix}addr add #{ud.ip.to_string} dev #{ud.ifname}")
                writer.lines.down("ip #{prefix}addr del #{ud.ip.to_string} dev #{ud.ifname}")
              end
              def render_ip_route(iface, ud)
                route = ud.route
                writer = etc_network_interfaces.get(iface, ud.ifname)
                metric = ""
                metric = " metric #{route.metric}" if route.metric
                routing_table = ""
                routing_table = " table #{route.via.routing_table}" if route.via.routing_table
                writer.lines.up("ip route add #{route.dst.to_string} via #{route.via.to_s} dev #{ud.ifname} #{metric}#{routing_table}")
                writer.lines.down("ip route del #{route.dst.to_string} via #{route.via.to_s} dev #{ud.ifname} #{metric}#{routing_table}")
              end
              def render_ip_route_table(iface, ud)
                route = ud.route
                ip = ud.ip
                writer = etc_network_interfaces.get(iface, ud.ifname)
                if ip.ipv4?
                  writer.lines.up("ip #{prefix}route add #{ip.to_string} dev #{ifname} proto kernel  scope link  src #{ip.to_s} table #{ip.routing_table.name}")
                  writer.lines.down("ip #{prefix}route del #{ip.to_string} dev #{ifname} proto kernel  scope link  src #{ip.to_s} table #{ip.routing_table.name}")
                end
                if ip.ipv6?
                  writer.lines.up("ip #{prefix}route add #{ip.to_string} dev #{ifname} proto kernel table #{ip.routing_table.name}")
                  writer.lines.down("ip #{prefix}route del #{ip.to_string} dev #{ifname} proto kernel table #{ip.routing_table.name}")
                end
                writer.lines.up("ip #{prefix}rule add from #{ip.to_s} table #{ip.routing_table.name}")
                writer.lines.down("ip #{prefix}rule del from #{ip.to_s} table #{ip.routing_table.name}")
              end

              def render_dns_masq(iface, ud)
                ifname = ud.ifname
                writer = etc_network_interfaces.get(iface, ud.ifname)
                dnsmasq_opts = [
                  "dnsmasq",
                  "-u dnsmasq",
                  "--strict-order",
                  "--pid-file=/run/#{ifname}-dnsmasq.pid",
                  "--conf-file=",
                  "--listen-address #{iface.address.first_ipv4}",
                  "--domain=#{iface.dhcp.get_domain}",
                  "--host-record=#{iface.host.name}.#{iface.dhcp.get_domain}.,#{iface.address.first_ipv4}",
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
              def render_dhcp_client(iface, ud)
                ifname = ud.ifname
                dhcp_client_opts = [
                  "/sbin/dhclient",
                  "-nw",
                  "-pf /run/dhclient.#{ifname}.pid",
                  "-lf /var/lib/dhcp/dhclient.#{ifname}.leases",
                  "-I",
                  "-df /var/lib/dhcp/dhclient6.#{ifname}.leases",
                  "#{ifname}"
                ]
                writer = etc_network_interfaces.get(iface, ud.ifname)
                writer.lines.up(dhcp_client_opts.join(" "), :extra)
                writer.lines.down("kill `cat /run/dhclient.#{ifname}.pid`", :extra)
              end
              def render_wlan(iface, ud)
                wlan = iface
                etc_network_interfaces.get(iface)
                  .lines.add(Construqt::Util.render(binding, "wlan_interfaces.erb"), 0)
              end
            end
          end
        end
      end
    end
  end
end
