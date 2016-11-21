module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          TASTES = {}
          def self.add(entity, impl)
            Tastes::Entities.add_taste(TASTES, entity, impl)
          end

          class Factory
            attr_accessor :result
            def initialize
              @tastes = {}
            end

            def dispatches(a)
              tastes = TASTES[a]
              throw "Debian #{a}" unless tastes
              @tastes[a] ||= tastes.map{|i| i.new }
            end

            def inspect
              "#<#{self.class.name}:#{object_id} @tastes=[#{@tastes.keys.join(",")}] @result=[#{@result.class.name}]>"
            end

          end
        end
      end
    end
  end
end



Dir.glob(File.join(File.dirname(__FILE__), "debian", "*.rb")).each do |fname|
  require fname
  # add("hello_world".split('_').collect(&:capitalize).join)
end

#
# module Construqt
#   module Flavour
#     module Nixian
#       module Dialect
#         module Ubuntu
#           class Result
#             ENTITIES = {}
#             def self.add(entity)
#               ENTITIES[entity.name] = entity
#             end
#
#
#             class UpDownerDebianTaste
#               attr_reader :dispatch
#               attr_reader :etc_network_interfaces, :etc_network_iptables, :etc_conntrackd_conntrackd
#
#               attr_reader :result
#
#               def result=(result)
#                 @result = result
#                 @etc_network_interfaces = EtcNetworkInterfaces.new(result)
#                 @etc_conntrackd_conntrackd = EtcConntrackdConntrackd.new(result)
#               end
#
#               def initialize()
#                 @etc_network_vrrp = EtcNetworkVrrp.new
#                 cp = Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::UpDown
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
#                 }
#                 # binding.pry
#               end
#
#               def register_srv(entity_actions)
#                 entity_actions.each do |e, action|
#                   throw "duplicated entity name for #{e}" if @dispatch[e]
#                   @dispatch[e] = action
#                 end
#               end
#
#               def commit
#                 result.add(EtcNetworkInterfaces, etc_network_interfaces.commit,
#                   Construqt::Resources::Rights.root_0644,
#                   'etc', 'network', 'interfaces')
#                 @etc_network_vrrp.commit(result)
#                 result.ipsec_secret.commit
#                 result.ipsec_cert_store.commit
#               end
#
#               def render_ip_route_table(iface, ud)
#                 route = ud.route
#                 ip = ud.ip
#                 writer = etc_network_interfaces.get(iface, ud.ifname)
#                 if ip.ipv4?
#                   writer.lines.up("ip #{prefix}route add #{ip.to_string} dev #{ifname} proto kernel  scope link  src #{ip.to_s} table #{ip.routing_table.name}")
#                   writer.lines.down("ip #{prefix}route del #{ip.to_string} dev #{ifname} proto kernel  scope link  src #{ip.to_s} table #{ip.routing_table.name}")
#                 end
#                 if ip.ipv6?
#                   writer.lines.up("ip #{prefix}route add #{ip.to_string} dev #{ifname} proto kernel table #{ip.routing_table.name}")
#                   writer.lines.down("ip #{prefix}route del #{ip.to_string} dev #{ifname} proto kernel table #{ip.routing_table.name}")
#                 end
#                 writer.lines.up("ip #{prefix}rule add from #{ip.to_s} table #{ip.routing_table.name}")
#                 writer.lines.down("ip #{prefix}rule del from #{ip.to_s} table #{ip.routing_table.name}")
#               end
#
#               def render_dns_masq(iface, ud)
#                 ifname = ud.ifname
#                 writer = etc_network_interfaces.get(iface, ud.ifname)
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
#                 writer.lines.up(dnsmasq_opts.join(" "))
#                 writer.lines.down("kill `cat /run/#{ifname}-dnsmasq.pid`")
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
#                 writer = etc_network_interfaces.get(iface, ud.ifname)
#                 writer.lines.up(dhcp_client_opts.join(" "), :extra)
#                 writer.lines.down("kill `cat /run/dhclient.#{ifname}.pid`", :extra)
#               end
#             end
#           end
#         end
#       end
#     end
#   end
# end
