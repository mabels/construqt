

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            class UpDownerSystemdTaste
              attr_reader :dispatch, :etc_systemd_netdev, :etc_systemd_network
              attr_accessor :result
              def initialize()
                @etc_systemd_netdev = EtcSystemdNetdev.new
                @etc_systemd_network = EtcSystemdNetwork.new

                cp = Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::UpDown
                @dispatch = {
                    cp::Device.name => lambda {|i, u| render_device(i, u) },
                    cp::Bgp.name => lambda {|i, u| render_bgp(i, u) },
                    cp::DhcpV4.name => lambda {|i, u| render_dhcp_v4(i, u) },
                    cp::DnsMasq.name => lambda {|i, u| render_dns_masq(i, u) },
                    cp::IpRule.name => lambda {|i, u| render_ip_rule(i, u) },
                    cp::OpenVpn.name => lambda {|i, u| render_open_vpn(i, u) },
                    cp::Bridge.name => lambda {|i, u| render_bridge(i, u) },
                    cp::DhcpV4Relay.name => lambda {|i, u| render_dhcp_v4_relay(i, u) },
                    cp::IpAddr.name => lambda {|i, u| render_ip_addr(i, u) },
                    cp::IpSecConnect.name => lambda {|i, u| render_ip_sec_connect(i, u) },
                    cp::BridgeMember.name => lambda {|i, u| render_bridge_member(i, u) },
                    cp::DhcpV6.name => lambda {|i, u| render_dhcp_v6(i, u) },
                    cp::IpProxyNeigh.name => lambda {|i, u| render_ip_proxy_neigh(i, u) },
                    cp::LinkMtuUpDown.name => lambda {|i, u| render_link_mtu_up_down(i, u) },
                    cp::Tunnel.name => lambda {|i, u| render_tunnel(i, u) },
                    cp::DhcpClient.name => lambda {|i, u| render_dhcp_client(i, u) },
                    cp::DhcpV6Relay.name => lambda {|i, u| render_dhcp_v6_relay(i, u) },
                    cp::IpRoute.name => lambda {|i, u| render_ip_route(i, u) },
                    cp::Loopback.name => lambda {|i, u| render_loopback(i, u) },
                    cp::Vlan.name => lambda {|i, u| render_vlan(i, u) },
                    cp::Wlan.name => lambda {|i, u| render_wlan(i, u) }
                }
                # binding.pry
              end
              def commit
                etc_systemd_netdev.commit(result)
                etc_systemd_network.commit(result)
              end

              def render_device(i, u)
              end

              def render_bgp(i, u)
              end
              def render_dhcp_v4(i, u)
              end
              def render_masq(i, u)
              end
              def render_ip_rule(i, u)
              end
              def render_open_vpn(i, u)
              end
              def render_bridge(i, u)
              end
              def render_dhcp_v4_relay(i, u)
              end
              def render_ip_sec_connect(i, u)
              end
              def render_bridge_member(i, u)
              end
              def render_dhcp_v6(i, u)
              end
              def render_ip_proxy_neigh(i, u)
              end
              def render_link_mtu_up_down(i, u)
              end
              def render_tunnel(i, u)
              end
              def render_vlan(i, u)
              end
              def render_loopback(i, u)
              end
              def render_ip_addr(i, u)
              end
              def render_ip_route(i, u)
              end
              def render_dns_masq(i, u)
              end
              def render_dhcp_client(i, u)
              end
              def render_wlan(i, u)
              end
            end
          end
        end
      end
    end
  end
end
