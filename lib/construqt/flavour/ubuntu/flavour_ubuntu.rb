
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

      #  class Interface < OpenStruct
      #    def initialize(cfg)
      #      super(cfg)
      #    end

      #    def build_config(host, iface)
      #      self.clazz.build_config(host, iface||self)
      #    end

      #  end

      class Device < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def self.add_address(host, ifname, iface, lines, writer)
          if iface.address.nil?
            Firewall.create(host, ifname, iface)
            return
          end

          writer.header.mode(EtcNetworkInterfaces::Entry::Header::MODE_DHCP) if iface.address.dhcpv4?
          writer.header.mode(EtcNetworkInterfaces::Entry::Header::MODE_LOOPBACK) if iface.address.loopback?
          lines.add(iface.flavour) if iface.flavour
          iface.address.ips.each do |ip|
            lines.up("ip addr add #{ip.to_string} dev #{ifname}")
            lines.down("ip addr del #{ip.to_string} dev #{ifname}")
          end

          iface.address.routes.each do |route|
            if route.metric
              metric = " metric #{route.metric}"
            else
              metric = ""
            end
            lines.up("ip route add #{route.dst.to_string} via #{route.via.to_s}#{metric}")
            lines.down("ip route del #{route.dst.to_string} via #{route.via.to_s}#{metric}")
          end

          Firewall.create(host, ifname, iface)
        end

        def build_config(host, iface)
          self.class.build_config(host, iface)
        end

        def self.add_services(host, ifname, iface, writer)
          iface.services && iface.services.each do |service|
            Services.get_renderer(service).interfaces(host, ifname, iface, writer)
          end
        end

        def self.build_config(host, iface)
          #      binding.pry
          writer = host.result.etc_network_interfaces.get(iface)
          writer.header.protocol(EtcNetworkInterfaces::Entry::Header::PROTO_INET4)
          #binding.pry #unless iface.delegate
          writer.lines.add(iface.delegate.flavour) if iface.delegate.flavour
          ifname = writer.header.get_interface_name
          #      ifaces.header.mode(Result::EtcNetworkInterfaces::Entry::Header::MODE_DHCP4) if iface.address.dhcpv4?
          #      ifaces.header.mode(Result::EtcNetworkInterfaces::Entry::Header::MODE_LOOOPBACK) if iface.address.loopback?
          writer.lines.up("ip link set mtu #{iface.delegate.mtu} dev #{ifname} up")
          writer.lines.down("ip link set dev #{ifname} down")
          add_address(host, ifname, iface.delegate, writer.lines, writer) #unless iface.address.nil? || iface.address.ips.empty?
          add_services(host, ifname, iface.delegate, writer)
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
          port_list = iface.interfaces.map { |i| i.name }.join(",")
          host.result.etc_network_interfaces.get(iface).lines.add("bridge_ports #{port_list}")
          Device.build_config(host, iface)
        end
      end

      class Host < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, unused)
          host.result.add(self, <<SCTL, Construqt::Resources::Rights::ROOT_0644, "etc", "sysctl.conf")
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.ipv4.vs.pmtu_disc=1

net.ipv6.conf.all.autoconf=0
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.all.forwarding=1
SCTL
          host.result.add(self, <<HOSTS, Construqt::Resources::Rights::ROOT_0644, "etc", "hosts")
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1       #{host.name} #{host.region.network.fqdn(host.name)}
HOSTS
          host.result.add(self, host.name, Construqt::Resources::Rights::ROOT_0644, "etc", "hostname")
          host.result.add(self, "# WTF resolvconf", Construqt::Resources::Rights::ROOT_0644, "etc", "resolvconf", "resolv.conf.d", "orignal");
          host.result.add(self,
                          (host.region.network.dns_resolver.nameservers.ips.map{|i| "nameserver #{i.to_s}" }+
                           ["search #{host.region.network.dns_resolver.search.join(' ')}"]).join("\n"),
                          Construqt::Resources::Rights::ROOT_0644, "etc", "resolv.conf")
          #binding.pry
          Dns.build_config(host) if host.delegate.dns_server
          akeys = []
          ykeys = []
          skeys = []
          host.region.users.all.each do |u|
            akeys << u.public_key if u.public_key
            ykeys << "#{u.name}:#{u.yubikey}" if u.yubikey
            skeys << "#{u.shadow}" if u.shadow
          end

          host.result.add(self, skeys.join(), Construqt::Resources::Rights::ROOT_0644, "etc", "shadow.merge")
          host.result.add(self, akeys.join(), Construqt::Resources::Rights::ROOT_0644, "root", ".ssh", "authorized_keys")
          host.result.add(self, ykeys.join("\n"), Construqt::Resources::Rights::ROOT_0644, "etc", "yubikey_mappings")

          host.result.add(self, <<SSH , Construqt::Resources::Rights::ROOT_0644, "etc", "ssh", "sshd_config")
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
          host.result.add(self, <<PAM , Construqt::Resources::Rights::ROOT_0644, "etc", "pam.d", "openvpn")
          #{host.delegate.yubikey ? '':'# '}auth required pam_yubico.so id=16 authfile=/etc/yubikey_mappings
auth [success=1 default=ignore] pam_unix.so nullok_secure try_first_pass
auth requisite pam_deny.so

@include common-account
@include common-session-noninteractive
PAM
          #binding.pry
          host.delegate.files && host.delegate.files.each do |file|
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
          #      binding.pry
          cfg = nil
          if gre_delegate.local.first_ipv6
            cfg = OpenStruct.new(:prefix=>6, :my=>gre_delegate.local.first_ipv6, :other => gre_delegate.remote.first_ipv6, :mode => "ip6gre")
          elsif gre_delegate.local.first_ipv4
            cfg = OpenStruct.new(:prefix=>4, :my=>gre_delegate.local.first_ipv4, :other => gre_delegate.remote.first_ipv4, :mode => "ipgre")
          end

          throw "need a local address #{host.name}:#{gre_delegate.name}" unless cfg
          local_iface = host.interfaces.values.find { |iface| iface.address.match_network(cfg.my) }
          throw "need a interface with address #{host.name}:#{cfg.my}" unless local_iface
          iname = Util.clean_if("gt#{cfg.prefix}", gre_delegate.name)

          writer_local = host.result.etc_network_interfaces.get(local_iface)
          writer_local.lines.up("/bin/bash /etc/network/#{iname}-up.iface")
          writer_local.lines.down("/bin/bash /etc/network/#{iname}-down.iface")


          writer = host.result.etc_network_interfaces.get(gre_delegate)
          writer.skip_interfaces.header.interface_name(iname)
          writer.lines.up("ip -#{cfg.prefix} tunnel add #{iname} mode #{cfg.mode} local #{cfg.my.to_s} remote #{cfg.other.to_s}")
          #      writer.lines.up("ip -#{cfg.prefix} link set dev #{iname} up")
          Device.build_config(host, gre)
          #      Device.add_address(host, iname, iface, writer.lines, writer)
          writer.lines.down("ip -#{cfg.prefix} tunnel del #{iname}")
        end
      end

      class Template < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
        end
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
          "vlan" => Vlan,
          "result" => Result,
          "ipsec" => Ipsec,
          "bgp" => Bgp,
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
        Ipsec.new(cfg)
      end
    end
  end
end
