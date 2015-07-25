
require_relative 'flavour_ubuntu_dns.rb'
require_relative 'flavour_ubuntu_ipsec.rb'
require_relative 'flavour_ubuntu_bgp.rb'
require_relative 'flavour_ubuntu_opvn.rb'
require_relative 'flavour_ubuntu_vrrp.rb'
require_relative 'flavour_ubuntu_firewall.rb'
require_relative 'flavour_ubuntu_result.rb'
require_relative 'flavour_ubuntu_services.rb'

module Construqt
  module Flavour
    module Ubuntu
      def self.name
        'ubuntu'
      end

      Flavour.add(self)

      class Device < OpenStruct
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
          writer.header.mode(EtcNetworkInterfaces::Entry::Header::MODE_LOOPBACK) if iface.address.loopback?
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
            puts "self.proxy_neigh2ips>>>>>#{neigh} #{ret.map{|i| i.class.name}} "
            return ret
          end
          return neigh.ips
        end

        def self.proxy_neigh(ifname, iface, lines)
          proxy_neigh2ips(iface.proxy_neigh).each do |ip|
            puts "**********#{ip.class.name}"
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

        def self.build_config(host, iface, ifname = nil, family = nil, mtu = nil)
          #      binding.pry
#          if iface.dynamic
#            Firewall.create(host, ifname||iface.name, iface, family)
#            return
#          end
          writer = host.result.etc_network_interfaces.get(iface, ifname)
          writer.header.protocol(EtcNetworkInterfaces::Entry::Header::PROTO_INET4)
          writer.lines.add(iface.delegate.flavour) if iface.delegate.flavour
          ifname = ifname || writer.header.get_interface_name
          writer.lines.up("ip link set mtu #{mtu || iface.delegate.mtu} dev #{ifname} up")
          writer.lines.down("ip link set dev #{ifname} down")
          add_address(host, ifname, iface.delegate, writer.lines, writer, family)
          add_services(host, ifname, iface.delegate, writer, family)
        end
      end

      class Bond < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, bond)
          bond_delegate = bond.delegate
          bond_delegate.interfaces.each do |i|
            host.result.etc_network_interfaces.get(i).lines.add("bond-master #{bond_delegate.name}")
          end

          mac_address = bond_delegate.mac_address || Construqt::Util.generate_mac_address_from_name("#{host.name} #{bond_delegate.name}")
          host.result.etc_network_interfaces.get(bond_delegate).lines.add(<<BOND)
pre-up ip link set dev #{bond_delegate.name} mtu #{bond_delegate.mtu} address #{mac_address}
bond-mode #{bond_delegate.mode||'active-backup'}
bond-miimon 100
bond-lacp-rate 1
bond-slaves none
BOND
          Device.build_config(host, bond)
        end
      end

      class Wlan < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, wlan)
          wlan_delegate = wlan.delegate

          mac_address = wlan_delegate.mac_address || Construqt::Util.generate_mac_address_from_name("#{host.name} #{wlan_delegate.name}")
          host.result.etc_network_interfaces.get(wlan_delegate).lines.add(<<BOND)
wpa-driver wext
wpa-ssid #{wlan_delegate.ssid}
wpa-ap-scan 1
wpa-proto RSN
wpa-pairwise CCMP
wpa-group CCMP
wpa-key-mgmt WPA-PSK
wpa-psk #{OpenSSL::PKCS5.pbkdf2_hmac_sha1(wlan_delegate.psk, wlan_delegate.ssid, 4096, 32).bytes.to_a.map{|i| "%0x"%i}.join("")}
BOND
          Device.build_config(host, wlan)
        end
      end

      class IpsecVpn < OpenStruct
        def initialize(cfg)
          super(cfg)
        end
        def build_config(host, iface)
          #puts ">>>>>>>>>>>>>>>>>>>>>>#{host.name} #{iface.name}"
          render_ipv6_proxy(iface)
          if iface.leftpsk
            self.host.result.add(self, render_psk(host, iface),
                                 Construqt::Resources::Rights::root_0600(Construqt::Resources::Component::IPSEC), "etc", "ipsec.secrets")
          end

          self.host.result.add(self, render_ikev1(host, iface), Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec.conf")
          self.host.result.add(self, render_ikev2(host, iface), Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec.conf")
        end

        def render_ipv6_proxy(iface)
          return unless iface.ipv6_proxy
          host.result.add(self, <<UPDOWN_SH, Construqt::Resources::Rights.root_0755, "etc", "ipsec.d", "#{iface.left_interface.name}-ipv6_proxy_updown.sh")
#!/bin/bash
if [ $PLUTO_VERB = "up-client-v6" ]
then
	ipaddr=$(echo $PLUTO_PEER_CLIENT | sed 's|/.*$||')
  logger "proxy-up-client_ipv6=$ipaddr:#{iface.left_interface.name}"
  ip -6 neigh add proxy $ipaddr dev #{iface.left_interface.name}
	exit 0
fi
if [ $PLUTO_VERB = "down-client-v6" ]
then
	ipaddr=$(echo $PLUTO_PEER_CLIENT | sed 's|/.*$||')
  logger "proxy-down-client_ipv6=$ipaddr:#{iface.left_interface.name}"
  ip -6 neigh del proxy $ipaddr dev #{iface.left_interface.name}
	exit 0
fi

#(date;echo $@;env) >> /tmp/ipsec.log
exit 0
UPDOWN_SH
        end

        def render_psk(host, iface)
          out = []
          out << "## #{host.name}-#{iface.name}"
          iface.left_interface.address.ips.each do |ip|
            out << "#{ip.to_s} %any : PSK \"#{iface.leftpsk}\""
          end
          out.join("\n")
        end

        def render_ikev1(host, iface)
          conn = OpenStruct.new
          conn.keyexchange = "ikev1"
          conn.leftauth = "psk"
          conn.left = [iface.left_interface.address.first_ipv4,iface.left_interface.address.first_ipv6].compact.join(",")
          conn.leftid = host.region.network.fqdn(host.name)
          conn.leftsubnet = "0.0.0.0/0,2000::/3"
          if iface.ipv6_proxy
            conn.leftupdown = "/etc/ipsec.d/#{iface.left_interface.name}-ipv6_proxy_updown.sh"
            conn.rightupdown = "/etc/ipsec.d/#{iface.left_interface.name}-ipv6_proxy_updown.sh"
          end
          conn.right = "%any"
          conn.rightsourceip = iface.right_address.ips.map{|i| i.network.to_string}.join(",")
          conn.rightauth = "psk"
          if iface.auth_method == :radius
            conn.rightauth2 = "xauth-radius"
          else
            conn.rightauth2 = "xauth"
          end
          conn.rightsendcert = "never"
          conn.auto = "add"
          render_conn(host, iface, conn)
        end

        def render_ikev2(host, iface)
          conn = OpenStruct.new
          conn.keyexchange = "ikev2"
          conn.leftauth = "pubkey"
          if iface.leftcert
            conn.leftcert = iface.leftcert.name
          end
          conn.left = [iface.left_interface.address.first_ipv4,iface.left_interface.address.first_ipv6].compact.join(",")
          conn.leftid = host.region.network.fqdn(host.name)
          conn.leftsubnet = "0.0.0.0/0,2000::/3"
          if iface.ipv6_proxy
            conn.leftupdown = "/etc/ipsec.d/#{iface.left_interface.name}-ipv6_proxy_updown.sh"
            conn.rightupdown = "/etc/ipsec.d/#{iface.left_interface.name}-ipv6_proxy_updown.sh"
          end
          conn.right = "%any"
          conn.rightsourceip = iface.right_address.ips.map{|i| i.network.to_string}.join(",")
          conn.rightauth = "eap-mschapv2"
          conn.eap_identity = "%any"
          conn.auto = "add"
          render_conn(host, iface, conn)

        end


        def render_conn(host, iface, conn)
          out = ["conn #{host.name}-#{iface.name}-#{conn.keyexchange}"]
          conn.to_h.each do |k,v|
            out << Util.indent("#{k}=#{v}", 3)
          end
          out.join("\n")
        end
      end

      class Vlan < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          vlan = iface.name.split('.')
          throw "vlan name not valid if.# => #{iface.name}" if vlan.length != 2 ||
            !vlan.first.match(/^[0-9a-zA-Z]+$/) ||
            !vlan.last.match(/^[0-9]+/) ||
            !(1 <= vlan.last.to_i && vlan.last.to_i < 4096)
          Device.build_config(host, iface)
        end
      end

      class Bridge < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          unless iface.interfaces.empty?
            port_list = iface.interfaces.map { |i| i.name }.join(",")
            host.result.etc_network_interfaces.get(iface).lines.add("bridge_ports #{port_list}")
          else
            host.result.etc_network_interfaces.get(iface).lines.add("bridge_ports none")
          end
          Device.build_config(host, iface)
        end
      end

      class Host < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, unused)
          host.result.add(self, <<UDEV, Construqt::Resources::Rights.root_0644, "etc", "udev", "rules.d", "23-persistent-vnet.rules")
# Construqt UDEV for container mtu
SUBSYSTEM=="net", ACTION=="add", KERNEL=="vnet*", ATTR{mtu}="#{host.interfaces.values.map { |iface| iface.mtu.to_i || 1500 }.max}"
UDEV
          host.result.add(self, <<SCTL, Construqt::Resources::Rights.root_0644, "etc", "sysctl.conf")
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.ipv4.vs.pmtu_disc=1

net.ipv6.conf.all.autoconf=0
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.all.forwarding=1

net.ipv6.conf.all.proxy_ndp=1
SCTL
          host.result.add(self, <<HOSTS, Construqt::Resources::Rights.root_0644, "etc", "hosts")
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1       #{host.name} #{host.region.network.fqdn(host.name)}
HOSTS
          host.result.add(self, host.name, Construqt::Resources::Rights.root_0644, "etc", "hostname")
          host.result.add(self, "# WTF resolvconf", Construqt::Resources::Rights.root_0644, "etc", "resolvconf", "resolv.conf.d", "orignal");
          host.result.add(self,
                          (host.region.network.dns_resolver.nameservers.ips.map{|i| "nameserver #{i.to_s}" }+
                           ["search #{host.region.network.dns_resolver.search.join(' ')}"]).join("\n"),
                          Construqt::Resources::Rights.root_0644, "etc", "resolv.conf")


          #binding.pry
          Dns.build_config(host) if host.delegate.dns_server
          ykeys = []
          skeys = []
          host.region.users.all.each do |u|
            ykeys << "#{u.name}:#{u.yubikey}" if u.yubikey
            skeys << "#{u.shadow}" if u.shadow
          end
          akeys = host.region.users.get_authorized_keys(host)

          #host.result.add(self, skeys.join(), Construqt::Resources::Rights.root_0644, "etc", "shadow.merge")
          host.result.add(self, akeys.join(), Construqt::Resources::Rights.root_0644, "root", ".ssh", "authorized_keys")
          host.result.add(self, ykeys.join("\n"), Construqt::Resources::Rights.root_0644, "etc", "yubikey_mappings")

          host.result.add(self, <<SSH , Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::SSH), "etc", "ssh", "sshd_config")
# Package generated configuration file
# See the sshd_config(5) manpage for details

# What ports, IPs and protocols we listen for
Port 22
# Use these options to restrict which interfaces/protocols sshd will bind to
#ListenAddress ::
#ListenAddress 0.0.0.0
Protocol 2
# HostKeys for protocol version 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
#Privilege Separation is turned on for security
UsePrivilegeSeparation yes

# Lifetime and size of ephemeral version 1 server key
KeyRegenerationInterval 3600
ServerKeyBits 1024

# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication:
LoginGraceTime 120
PermitRootLogin without-password
StrictModes yes

RSAAuthentication yes
PubkeyAuthentication yes
#AuthorizedKeysFile	%h/.ssh/authorized_keys

# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes
# For this to work you will also need host keys in /etc/ssh_known_hosts
RhostsRSAAuthentication no
# similar for protocol version 2
HostbasedAuthentication no
# Uncomment if you don't trust ~/.ssh/known_hosts for RhostsRSAAuthentication
#IgnoreUserKnownHosts yes

# To enable empty passwords, change to yes (NOT RECOMMENDED)
PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Change to no to disable tunnelled clear text passwords
PasswordAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosGetAFSToken no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes

X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
#UseLogin no

#MaxStartups 10:30:60
#Banner /etc/issue.net

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
UsePAM yes
SSH
          #binding.pry
          host.delegate.files && host.delegate.files.each do |file|
            next if file.kind_of?(Construqt::Resources::SkipFile)
            if host.result.replace(nil, file.data, file.right, *file.path)
              Construqt.logger.warn("the file #{file.path} was overriden!")
            end
          end
        end
      end

      class Gre < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, gre)
          gre_delegate = gre.delegate
          prepare = { }
          if gre.ipsec.transport_family.nil? || gre.ipsec.transport_family == Construqt::Addresses::IPV6
            my = gre_delegate.local.first_ipv6
            other = gre_delegate.other.interface.delegate.local.first_ipv6
            remote = gre_delegate.remote.first_ipv6
            mode_v6 = "ip6gre"
            mode_v4 = "ipip6"
            prefix = 6
          else
            remote = gre_delegate.remote.first_ipv4
            other = gre_delegate.other.interface.delegate.local.first_ipv4
            my = gre_delegate.local.first_ipv4
            mode_v6 = "sit"
            mode_v4 = "gre"
            prefix = 4
          end
          #binding.pry
          if gre_delegate.local.first_ipv6
            prepare[6] = OpenStruct.new(:gt => "gt6", :prefix=>prefix, :family => Construqt::Addresses::IPV6,
                                        :my => my, :other => other, :remote => remote, :mode => mode_v6,
                                        :mtu => gre.ipsec.mtu_v6 || 1460)
          end

          if gre_delegate.local.first_ipv4
            prepare[4] = OpenStruct.new(:gt => "gt4", :prefix=>prefix, :family => Construqt::Addresses::IPV4,
                                    :my=>my, :other => other, :remote => remote, :mode => mode_v4,
                                    :mtu => gre.ipsec.mtu_v4 || 1476)
          end
          throw "need a local address #{host.name}:#{gre_delegate.name}" if prepare.empty?

          #ip -6 tunnel add gt6naspr01 mode ip6gre local 2a04:2f80:f:f003::2 remote 2a04:2f80:f:f003::1
          #ip link set mtu 1500 dev gt6naspr01 up
          #ip addr add 2a04:2f80:f:f003::2/64 dev gt6naspr01

          #ip -4 tunnel add gt4naspr01 mode gre local 169.254.193.2 remote 169.254.193.1
          #ip link set mtu 1500 dev gt4naspr01 up
          #ip addr add 169.254.193.2/30 dev gt4naspr01

          local_ifaces = {}
          prepare.values.each do |cfg|
            local_iface = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(cfg.remote.ipaddr) }
            throw "need a interface with address #{host.name}:#{cfg.remote.ipaddr}" unless local_iface

            iname = Util.clean_if(cfg.gt, gre_delegate.name)
            local_ifaces[local_iface.name] ||= OpenStruct.new(:iface => local_iface, :inames => [])
            local_ifaces[local_iface.name].inames << iname

            writer = host.result.etc_network_interfaces.get(gre, iname)
            writer.skip_interfaces.header.interface_name(iname)
            writer.lines.up("ip -#{cfg.prefix} tunnel add #{iname} mode #{cfg.mode} local #{cfg.my.to_s} remote #{cfg.other.to_s}")
            Device.build_config(host, gre, iname, cfg.family, cfg.mtu)
            writer.lines.down("ip -#{cfg.prefix} tunnel del #{iname}")
          end
          local_ifaces.values.each do |val|
            if val.iface.clazz == "vrrp"
              vrrp = host.result.etc_network_vrrp(val.iface.name)
              val.inames.each do |iname|
                vrrp.add_master("/bin/bash /etc/network/#{iname}-up.iface")
              end
              val.inames.each do |iname|
                vrrp.add_backup("/bin/bash /etc/network/#{iname}-down.iface")
              end
            else
              writer_local = host.result.etc_network_interfaces.get(val.iface)
              val.inames.each do |iname|
                writer_local.lines.up("/bin/bash /etc/network/#{iname}-up.iface")
                writer_local.lines.down("/bin/bash /etc/network/#{iname}-down.iface")
              end
            end
          end
        end
      end

      class Template < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
        end
      end

      def self.ipsec
        StrongSwan::Ipsec
      end

      def self.bgp
        Bgp
      end

      def self.clazzes
        {
          "opvn" => Opvn,
          "gre" => Gre,
          "host" => Host,
          "device"=> Device,
          "vrrp" => Vrrp,
          "bridge" => Bridge,
          "bond" => Bond,
          "wlan" => Wlan,
          "vlan" => Vlan,
          "ipsecvpn" => IpsecVpn,
          #"result" => Result,
          #"ipsec" => Ipsec,
          #"bgp" => Bgp,
          "template" => Template
        }
      end

      def self.clazz(name)
        ret = self.clazzes[name]
        throw "class not found #{name}" unless ret
        ret
      end

      def self.create_host(name, cfg)
        cfg['name'] = name
        cfg['result'] = nil
        host = Host.new(cfg)
        host.result = Result.new(host)
        host
      end

      def self.create_interface(name, cfg)
        cfg['name'] = name
        clazz(cfg['clazz']).new(cfg)
      end

      def self.create_bgp(cfg)
        Bgp.new(cfg)
      end

      def self.create_ipsec(cfg)
        StrongSwan::Ipsec.new(cfg)
      end
    end
  end
end
