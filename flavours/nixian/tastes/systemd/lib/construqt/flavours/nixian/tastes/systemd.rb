
module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          TASTES = {}
          def self.add(entity, impl)
            Tastes::Entities.add_taste(TASTES, entity, impl)
          end
          class Factory
            def initialize
              @tastes = TASTES.clone
              @activated = {}
              # @etc_network_interfaces = Helper::EtcNetworkInterfaces.new(self)
            end

            def add(entity, impl)
              Tastes::Entities.add_taste(@tastes, entity, impl)
            end

            def activate(ctx)
              @context = ctx
            end

            def dispatches(a)
              taste = @tastes[a]
              if taste
                @activated[a] ||= taste.map{|i| i.new.activate(@context) }
              else
                []
              end
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


Dir.glob(File.join(File.dirname(__FILE__), "systemd", "*.rb")).each do |fname|
  require fname
  # add("hello_world".split('_').collect(&:capitalize).join)
end

#
#
# require_relative 'etc_systemd_service'
#
# module Construqt
#   module Flavour
#     module Nixian
#       module Dialect
#         module Ubuntu
#           class Result
#             class UpDownerSystemdTaste
#               attr_reader :dispatch, :etc_systemd_netdev, :etc_systemd_network
#               attr_reader :etc_systemd_service
#               attr_accessor :result
#               def initialize()
#                 @etc_systemd_netdev = EtcSystemdNetdev.new
#                 @etc_systemd_network = EtcSystemdNetwork.new
#                 @etc_systemd_service = EtcSystemdService.new
#
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
#               def commit
#                 result.add(self, etc_systemd_service.services.keys.join("\n"),
#                   Construqt::Resources::Rights.root_0644,
#                   'etc', 'systemd', 'construqt.services')
#                 result.add(self, Util.render(binding, "clean-systemd.sh.erb"),
#                   Construqt::Resources::Rights.root_0644,
#                   'etc', 'systemd', 'clean-systemd.sh')
#                 etc_systemd_service.get("construqt-clean-systemd-config") do |service|
#                   service.exec_start("/etc/systemd/construqt-clean-systemd.sh /etc/systemd/construqt.services")
#                 end
#                 etc_systemd_netdev.commit(result)
#                 etc_systemd_network.commit(result)
#                 etc_systemd_service.commit(result)
#               end
#
#               def render_iptables(iface, ud)
#                 etc_systemd_service.get("construqt-iptables") do |service|
#                   service.exec_start("iptables-restore /etc/network/iptables.cfg")
#                   service.exec_start("ip6tables-restore /etc/network/ip6tables.cfg")
#                 end
#               end
#
#               def render_device(i, ud)
#               end
#
#               def render_bgp(i, ud)
#                 etc_systemd_service.get("construqt-bgp") do |service|
#                   throw "not implemented"
#                   writer.lines.up("/usr/sbin/#{cmd} enable #{cname}", 2000, :extra)
#                   writer.lines.down("/usr/sbin/#{cmd} disable #{cname}", -2000, :extra)
#                 end
#               end
#
#               def render_dhcp_v4(iface, u)
#                 # do nothing it will be done be the template
#               end
#
#               def render_open_vpn(iface, u)
#                 etc_systemd_service.get("construqt-prepare-openvpn") do |service|
#                   service.exec_start("mkdir -p /dev/net; mknod /dev/net/tun c 10 200")
#                 end
#                 etc_systemd_service.get("construqt-start-openvpn-#{iface.name}") do |service|
#                   service.exec_start("/usr/sbin/openvpn --config /etc/openvpn/#{iface.name}.conf")
#                 end
#               end
#
#               def render_bridge(i, u)
#                 # do nothing
#               end
#
#               def render_ip_sec_connect(iface, ud)
#                 etc_systemd_service.get("construqt-ipsec-daemon") do |service|
#                   service.exec_start("/usr/sbin/ipsec start")
#                   service.exec_stop("/usr/sbin/ipsec stop")
#                 end
#                 etc_systemd_service.get("construqt-ipsec@#{ud.name}") do |service|
#                   service.exec_start("/usr/sbin/ipsec up #{ud.name}")
#                   service.exec_stop("/usr/sbin/ipsec down #{ud.name}")
#                 end
#               end
#               def render_bridge_member(i, u)
#                 # do nothing
#               end
#               def render_dhcp_v6(i, u)
#                 # do nothing network template
#               end
#               def render_ip_proxy_neigh(i, ud)
#                 etc_systemd_service.get("construqt-ip-neigh@#{ud.ifname}") do |service|
#                   service.exec_start("/etc/network/#{ud.ifname}-neigh-up.sh")
#                   service.exec_stop("/etc/network/#{ud.ifname}-neigh-down.sh")
#                 end
#               end
#               def render_link_mtu_up_down(i, u)
#                 # do nothing network template
#               end
#               def render_tunnel(iface, ud)
#                 etc_systemd_service.get("construqt-ip-tunnel@#{iface.name}") do |service|
#                   service.exec_start("ip -#{ud.cfg.prefix} tunnel add #{iface.name} mode #{ud.cfg.mode} local #{ud.local} remote #{ud.remote}")
#                   service.exec_stop("ip -#{ud.cfg.prefix} tunnel del #{iface.name}")
#                 end
#               end
#               def render_vlan(i, u)
#                 # do nothing network template
#               end
#               def render_loopback(i, u)
#                 # do nothing network template
#               end
#               def render_ip_addr(i, u)
#                 # do nothing network template
#               end
#               def render_ip_route(i, u)
#                 # do nothing network template
#               end
#               def render_dns_masq(i, u)
#                 # move away
#               end
#               def render_dhcp_client(i, u)
#                 # move away
#               end
#               def render_wlan(iface, u)
#                 etc_systemd_service.get("construqt-wpa_supplicant@#{iface.name}") do |service|
#                   service.exec_start("/usr/bin/wpa_supplicant -c/etc/network/#{iface.name}-wpa_supplicant.conf -i#{iface.name} -Dnl80211,wext")
#                 end
#               end
#             end
#           end
#         end
#       end
#     end
#   end
# end
