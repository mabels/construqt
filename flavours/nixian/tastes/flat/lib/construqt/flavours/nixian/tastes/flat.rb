module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Flat
          TASTES = {}
          def self.add(entity, impl)
            Tastes::Entities.add_taste(TASTES, entity, impl)
          end
          class Factory
            attr_accessor :result
            def initialize
              @tastes = {}
            end

            def activate(ctx)
              @context = ctx
            end

            def dispatches(a)
              tastes = TASTES[a]
              throw "Flat #{a}" unless tastes
              @tastes[a] ||= tastes.map{|i| i.new.activate(@context) }
            end

            def inspect
              "#<#{self.class.name}:#{object_id} @tastes=#{@tastes.keys.join(",")} @result=#{@result.class.name}>"
            end

          end
        end
      end
    end
  end
end



Dir.glob(File.join(File.dirname(__FILE__), "flat", "*.rb")).each do |fname|
  require fname
  # add("hello_world".split('_').collect(&:capitalize).join)
end

# module Construqt
#   module Flavour
#     module Nixian
#       module Dialect
#         module Ubuntu
#           class Result
#             class UpDownerFlatTaste
#               attr_reader :dispatch
#               attr_accessor :result
#               def initialize()
#                 cp = Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::UpDown
#                 @ups = []
#                 @downs = []
#                 @dispatch = {
#                     cp::Device.name => lambda {|i, u| render_device(i, u) },
#                     cp::Bgp.name => lambda {|i, u| render_bgp(i, u) },
#                     cp::DhcpV4.name => lambda {|i, u| render_dhcp_v4(i, u) },
#                     cp::DnsMasq.name => lambda {|i, u| render_dns_masq(i, u) },
#                     cp::OpenVpn.name => lambda {|i, u| render_open_vpn(i, u) },
#                     cp::Bridge.name => lambda {|i, u| render_bridge(i, u) },
#                     cp::IpAddr.name => lambda {|i, u| render_ip_addr(i, u) },
#                     cp::IpSecConnect.name => lambda {|i, u| render_ip_sec_connect(i, u) },
#                     cp::BridgeMember.name => lambda {|i, u| render_bridge_member(i, u) },
#                     cp::DhcpV6.name => lambda {|i, u| render_dhcp_v6(i, u) },
#                     cp::IpProxyNeigh.name => lambda {|i, u| render_ip_proxy_neigh(i, u) },
#                     cp::LinkMtuUpDown.name => lambda {|i, u| render_link_mtu_up_down(i, u) },
#                     cp::Tunnel.name => lambda {|i, u| render_tunnel(i, u) },
#                     cp::DhcpClient.name => lambda {|i, u| render_dhcp_client(i, u) },
#                     cp::IpRoute.name => lambda {|i, u| render_ip_route(i, u) },
#                     cp::Loopback.name => lambda {|i, u| render_loopback(i, u) },
#                     cp::Vlan.name => lambda {|i, u| render_vlan(i, u) },
#                     cp::Wlan.name => lambda {|i, u| render_wlan(i, u) },
#                     cp::IpTables.name => lambda {|i, u| render_iptables(i, u) }
#
#                 }
#                 # binding.pry
#               end
#               def up(line)
#                 @ups.push line
#               end
#               def down(line)
#                 @downs.push line
#               end
#
#               def commit
#                 unless @ups.empty?
#                   result.add(self, (["#!/bin/sh"]+@ups).join("\n"),
#                     Construqt::Resources::Rights.root_0755,
#                     'etc', 'network', 'flat_network_up.sh')
#                 end
#                 unless @downs.empty?
#                   result.add(self, (["#!/bin/sh"]+@downs.reverse).join("\n"),
#                     Construqt::Resources::Rights.root_0644,
#                     'etc', 'network', 'flat_network_down.sh')
#                 end
#               end
#
#               def render_iptables(i, u)
#                 up("/sbin/iptables-restore /etc/network/iptables.cfg")
#                 up("/sbin/ip6tables-restore /etc/network/ip6tables.cfg")
#               end
#
#
#               def render_device(i, u)
#               end
#
#               def render_bgp(i, u)
#                 up("/usr/sbin/#{cmd} enable #{cname}", 2000, :extra)
#                 down("/usr/sbin/#{cmd} disable #{cname}", -2000, :extra)
#               end
#               def render_dhcp_v4(i, u)
#               end
#               def render_masq(i, u)
#               end
#               def render_open_vpn(iface, ud)
#                 up("mkdir -p /dev/net")
#                 up("mknod /dev/net/tun c 10 200")
#                 up("/usr/sbin/openvpn --config /etc/openvpn/#{iface.name}.conf")
#                 down("kill $(cat /run/openvpn.#{iface.name}.pid)")
#               end
#               def render_bridge(i, ud)
#                 up("brctl addbr #{ud.ifname}")
#                 down("brctl delbr #{ud.ifname}")
#               end
#               def render_ip_sec_connect(iface, ud)
#                 up("/usr/sbin/ipsec start") # no down this is also global
#                 up("/usr/sbin/ipsec up #{ud.name} &")
#                 down("/usr/sbin/ipsec down #{ud.name} &")
#               end
#               def render_bridge_member(i, ud)
#                 up "brctl addif #{ud.bname} #{ud.ifname}"
#                 down "brctl delif #{ud.bname} #{ud.ifname}"
#               end
#               def render_dhcp_v6(i, u)
#               end
#               def render_ip_proxy_neigh(iface, ud)
#                 ipv = ud.ip.ipv6? ? "-6 ": "-4 "
#                 up("ip #{ipv}neigh add proxy #{ud.ip.to_s} dev #{ud.ifname}")
#                 down("ip #{ipv}neigh del proxy #{ud.ip.to_s} dev #{ud.ifname}")
#               end
#               def render_link_mtu_up_down(i, u)
#               end
#               def render_tunnel(iface, ud)
#                 up("ip -#{ud.cfg.prefix} tunnel add #{iface.name} mode #{ud.cfg.mode} local #{ud.local} remote #{ud.remote}")
#                 down("ip -#{ud.cfg.prefix} tunnel del #{iface.name}")
#               end
#               def render_vlan(iface, ud)
#                 up("ip link add link #{ud.dev_name(iface)} name #{iface.name} type vlan id #{ud.vlan_id(iface)}")
#                 down("ip link delete dev #{iface.name} type vlan id #{ud.vlan_id(iface)}")
#               end
#               def render_loopback(i, u)
#               end
#               def render_ip_addr(iface, ud)
#                 prefix = ud.ip.ipv6? ? "-6 " : "-4 "
#                 up("ip #{prefix}addr add #{ud.ip.to_string} dev #{ud.ifname}")
#                 down("ip #{prefix}addr del #{ud.ip.to_string} dev #{ud.ifname}")
#               end
#               def render_ip_route(iface, ud)
#                 route = ud.route
#                 metric = ""
#                 metric = " metric #{route.metric}" if route.metric
#                 routing_table = ""
#                 routing_table = " table #{route.via.routing_table}" if route.via.routing_table
#                 up("ip route add #{route.dst.to_string} via #{route.via.to_s} dev #{ud.ifname} #{metric}#{routing_table}")
#                 down("ip route del #{route.dst.to_string} via #{route.via.to_s} dev #{ud.ifname} #{metric}#{routing_table}")
#               end
#               def render_ip_route_table(iface, ud)
#                 route = ud.route
#                 ip = ud.ip
#                 if ip.ipv4?
#                   up("ip #{prefix}route add #{ip.to_string} dev #{ifname} proto kernel  scope link  src #{ip.to_s} table #{ip.routing_table.name}")
#                   down("ip #{prefix}route del #{ip.to_string} dev #{ifname} proto kernel  scope link  src #{ip.to_s} table #{ip.routing_table.name}")
#                 end
#                 if ip.ipv6?
#                   up("ip #{prefix}route add #{ip.to_string} dev #{ifname} proto kernel table #{ip.routing_table.name}")
#                   down("ip #{prefix}route del #{ip.to_string} dev #{ifname} proto kernel table #{ip.routing_table.name}")
#                 end
#                 up("ip #{prefix}rule add from #{ip.to_s} table #{ip.routing_table.name}")
#                 down("ip #{prefix}rule del from #{ip.to_s} table #{ip.routing_table.name}")
#               end
#
#               def render_dns_masq(iface, ud)
#                 ifname = ud.ifname
#                 dnsmasq_opts = [
#                   "dnsmasq",
#                   "-u dnsmasq",
#                   "--strict-order",
#                   "--pid-file=/run/#{ifname}-dnsmasq.pid",
#                   "--conf-file=",
#                   "--listen-address #{iface.address.first_ipv4}",
#                   "--domain=#{iface.dhcp.get_domain}",
#                   "--host-record=#{iface.host.name}.#{iface.dhcp.get_domain}.,#{iface.address.first_ipv4}",
#                   "--dhcp-range #{iface.dhcp.get_start},#{iface.dhcp.get_end}",
#                   "--dhcp-lease-max=253",
#                   "--dhcp-no-override",
#                   "--except-interface=lo",
#                   "--interface=#{ifname}",
#                   "--dhcp-leasefile=/var/lib/misc/dnsmasq.#{ifname}.leases",
#                   "--dhcp-authoritative"
#                 ]
#                 up(dnsmasq_opts.join(" "))
#                 down("kill `cat /run/#{ifname}-dnsmasq.pid`")
#               end
#               def render_dhcp_client(iface, ud)
#                 ifname = ud.ifname
#                 dhcp_client_opts = [
#                   "/sbin/dhclient",
#                   "-nw",
#                   "-pf /run/dhclient.#{ifname}.pid",
#                   "-lf /var/lib/dhcp/dhclient.#{ifname}.leases",
#                   "-I",
#                   "-df /var/lib/dhcp/dhclient6.#{ifname}.leases",
#                   "#{ifname}"
#                 ]
#                 up(dhcp_client_opts.join(" "))
#                 down("kill `cat /run/dhclient.#{ifname}.pid`")
#               end
#               def render_wlan(i, u)
#               end
#             end
#           end
#         end
#       end
#     end
#   end
# end
