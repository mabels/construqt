
module Construqt
  module Flavour
    module Ubuntu
      class Opvn < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, opvn)
          iface = opvn.delegate
          local = iface.ipv6 ? host.id.first_ipv6.first_ipv6 : host.id.first_ipv4.first_ipv4
          return unless local
          push_routes = ""
          if iface.push_routes
            push_routes = iface.push_routes.routes.each{|route| "push \"route #{route.dst.to_string}\"" }.join("\n")
          end

          host.result.add(self, iface.cacert, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}-cacert.pem")
          host.result.add(self, iface.hostcert, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}-hostcert.pem")
          host.result.add(self, iface.hostkey, Construqt::Resources::Rights.root_0600(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}-hostkey.pem")
          host.result.add(self, iface.dh1024, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "ssl", "#{iface.name}-dh1024")
          host.result.add(self, <<OPVN, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::OPENVPN), "etc", "openvpn", "#{iface.name}.conf")
daemon
local #{local}
proto udp#{local.ipv6? ? '6' : ''}
port 1194
mode server
tls-server
dev #{iface.name}
ca   /etc/openvpn/ssl/#{iface.name}-cacert.pem
cert /etc/openvpn/ssl/#{iface.name}-hostcert.pem
key  /etc/openvpn/ssl/#{iface.name}-hostkey.pem
dh   /etc/openvpn/ssl/#{iface.name}-dh1024
server #{iface.network.first_ipv4.to_s} #{iface.network.first_ipv4.netmask}
server-ipv6 #{iface.network.first_ipv6.to_string}
client-to-client
keepalive 10 30
cipher AES-128-CBC   # AES
cipher BF-CBC        # Blowfish (default)
comp-lzo
max-clients 100
user nobody
group nogroup
persist-key
persist-tun
status /etc/openvpn/status
log-append  /var/log/openvpn-#{iface.name}.log
mute 20
          #{push_routes}
mssfix #{iface.mtu||1348}
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so openvpn
client-cert-not-required
script-security 2
OPVN
        end
      end
    end
  end
end
