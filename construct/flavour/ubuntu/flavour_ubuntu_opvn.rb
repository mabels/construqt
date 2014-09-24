
module Construct
module Flavour
module Ubuntu
	module Opvn
		def self.header(path)
			"# this is a generated file do not edit!!!!!"
		end
		def self.build_config(host, iface)
      local = iface.ipv6 ? host.id.first_ipv6.first_ipv6 : host.id.first_ipv4.first_ipv4
      return unless local
			host.result.add(self, <<OPVN, Ubuntu.root, "etc", "openvpn", "#{iface.name}.conf")
daemon
local #{local}
proto udp#{local.ipv6? ? '6' : ''}
port 1194
mode server
tls-server
dev #{iface.name}
ca   /etc/openvpn/ssl/cacert.pem
cert /etc/openvpn/ssl/hostcert.pem
key  /etc/openvpn/ssl/hostkey.pem
dh   /etc/openvpn/ssl/dh1024.pem
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
push "route fd00:bacc::/32" 
mssfix 1348
#plugin /usr/lib/openvpn/openvpn-auth-ldap.so /etc/openvpn/auth-xx.cfg
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so openvpn
client-cert-not-required
script-security 2
OPVN
		end
	end
end
end
end
