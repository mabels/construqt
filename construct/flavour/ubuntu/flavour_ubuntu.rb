
require 'ostruct'
require 'construct/flavour/flavour.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_dns.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_ipsec.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_bgp.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_opvn.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_firewall.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_result.rb'
require "base64"

module Construct
module Flavour
module Ubuntu
  def self.name
    'ubuntu'
  end
  Flavour.add(self)    

  class Interface < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
    def build_config(host, unused)
      self.clazz.build_config(host, self)
    end
  end

  module Device
    def self.prefix(path)
      "# this is a generated file do not edit!!!!!"
    end
    def self.add_address(host, ifname, iface, lines, ifaces)
      if iface.address.nil?
        Firewall.create(host, ifname, iface)
        return
      end
      ifaces.header.mode(EtcNetworkInterfaces::Entry::Header::MODE_DHCP) if iface.address.dhcpv4?
      ifaces.header.mode(EtcNetworkInterfaces::Entry::Header::MODE_LOOPBACK) if iface.address.loopback?
      lines.add(iface.flavour) if iface.flavour
      iface.address.ips.each do |ip|
        lines.add("up ip addr add #{ip.to_string} dev #{ifname}")
        lines.add("down ip addr del #{ip.to_string} dev #{ifname}")
      end
      iface.address.routes.each do |route|
        lines.add("up ip route add #{route.dst.to_string} via #{route.via.to_s}")
        lines.add("down ip route del #{route.dst.to_string} via #{route.via.to_s}")
      end
      Firewall.create(host, ifname, iface)
    end
    def self.build_config(host, iface)
      #binding.pry if iface.name == "eth1"
      ifaces = host.result.delegate.etc_network_interfaces.get(iface)
      ifaces.header.protocol(EtcNetworkInterfaces::Entry::Header::PROTO_INET4)
      ifaces.lines.add(iface.flavour) if iface.flavour
      ifname = ifaces.header.interface_name || iface.name
#      ifaces.header.mode(Result::EtcNetworkInterfaces::Entry::Header::MODE_DHCP4) if iface.address.dhcpv4?
#      ifaces.header.mode(Result::EtcNetworkInterfaces::Entry::Header::MODE_LOOOPBACK) if iface.address.loopback?
      ifaces.lines.add("up ip link set mtu #{iface.mtu} dev #{ifname} up")
      ifaces.lines.add("down ip link set dev #{ifname} down")
      add_address(host, ifname, iface, ifaces.lines, ifaces) #unless iface.address.nil? || iface.address.ips.empty?
    end
  end
  module Vrrp
    def self.prefix(path)
      "# this is a generated file do not edit!!!!!"
    end
    def self.build_config(host, iface)
      my_iface = iface.interfaces.find{|iface| iface.host == host }
      ret = []
      ret << "global_defs {"
      ret << "  lvs_id #{host.name}"
      ret << "}"
      ret << "vrrp_instance #{iface.name} {"
      ret << "  state MASTER"
      ret << "  interface #{my_iface.name}"
      ret << "  virtual_router_id #{iface.vrid}"
      ret << "  priority #{my_iface.priority}"
      ret << "  authentication {"
      ret << "        auth_type PASS"
      ret << "        auth_pass fw"
      ret << "  }"
      ret << "  virtual_ipaddress {"
      iface.address.ips.each do |ip|
        ret << "    #{ip.to_string} dev #{my_iface.name}"  
      end
      ret << "  }"
      ret << "}"
      host.result.add(self, ret.join("\n"), Ubuntu.root, "etc", "keepalived", "keepalived.conf")
    end
  end
  module Bond
    def self.build_config(host, iface)
      iface.interfaces.each do |i|
        host.result.delegate.etc_network_interfaces.get(i).lines.add("bond-master #{iface.name}")
      end
      mac_address=Digest::SHA256.hexdigest("#{host.name} #{iface.name}").scan(/../)[0,6].join(':')
      host.result.delegate.etc_network_interfaces.get(iface).lines.add(<<BOND)
pre-up ip link set dev #{iface.name} mtu #{iface.mtu} address #{mac_address}
bond-mode #{iface.mode||'active-backup'}
bond-miimon 100
bond-lacp-rate 1
bond-slaves none
BOND
      Device.build_config(host, iface)
    end
  end
  module Vlan
    def self.build_config(host, iface)
      vlan = iface.name.split('.')
      throw "vlan name not valid if.# => #{iface.name}" if vlan.length != 2 || 
                                                        !vlan.first.match(/^[0-9a-zA-Z]+$/) || 
                                                        !vlan.last.match(/^[0-9]+/) ||
                                                        !(1 <= vlan.last.to_i && vlan.last.to_i < 4096)
      Device.build_config(host, iface)
    end
  end
  module Bridge
    def self.build_config(host, iface)
      port_list = iface.interfaces.map { |i| i.name }.join(",")
      host.result.delegate.etc_network_interfaces.get(iface).lines.add("bridge_ports #{port_list}")
      Device.build_config(host, iface)
    end
  end
  module Host
    def self.prefix(path)
      "# this is a generated file do not edit!!!!!"
    end
    def self.build_config(host, unused)
      host.result.add(self, <<SCTL, Ubuntu.root, "etc", "sysctl.conf")
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.default.forwarding = 1
net.ipv4.vs.pmtu_disc=1

net.ipv6.conf.all.autoconf=0
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.all.forwarding=1
SCTL
      host.result.add(self, host.name, Ubuntu.root_644, "etc", "hostname")
      host.result.add(self, "# WTF resolvconf", Ubuntu.root_644, "etc", "resolvconf", "resolv.conf.d", "orignal");
      host.result.add(self, <<RESOLVCONF,  Ubuntu.root_644, "etc", "resolv.conf")
nameserver 2001:4860:4860::8844
nameserver 2001:4860:4860::8888
nameserver 8.8.8.8
nameserver 8.8.4.4
search bb.s2betrieb.de
RESOLVCONF
      Dns.build_config(host) if host.dns_server
      akeys = []
      ykeys = []
      skeys = []
      host.region.users.all.each do |u|
        akeys << u.public_key if u.public_key
        ykeys << "#{u.name}:#{u.yubikey}" if u.yubikey
        skeys << "#{u.shadow}" if u.shadow
      end
      host.result.add(self, skeys.join(), Ubuntu.root_600, "etc", "shadow.merge")
      host.result.add(self, akeys.join(), Ubuntu.root_600, "root", ".ssh", "authorized_keys")
      host.result.add(self, ykeys.join("\n"), Ubuntu.root_644, "etc", "yubikey_mappings")

      host.result.add(self, <<SSH , Ubuntu.root_644, "etc", "ssh", "sshd_config")
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
      host.result.add(self, <<PAM , Ubuntu.root_644, "etc", "pam.d", "common-auth")
#
# /etc/pam.d/common-auth - authentication settings common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of the authentication modules that define
# the central authentication scheme for use on the system
# (e.g., /etc/shadow, LDAP, Kerberos, etc.).  The default is to use the
# traditional Unix authentication mechanisms.
#
# As of pam 1.0.1-6, this file is managed by pam-auth-update by default.
# To take advantage of this, it is recommended that you configure any
# local modules either before or after the default block, and use
# pam-auth-update to manage selection of other modules.  See
# pam-auth-update(8) for details.

auth required pam_yubico.so id=16 authfile=/etc/yubikey_mappings 
auth [success=1 default=ignore] pam_unix.so nullok_secure try_first_pass
auth requisite pam_deny.so

# here are the per-package modules (the "Primary" block)
#X auth  [success=1 default=ignore]  pam_unix.so nullok_secure
# here's the fallback if no module succeeds
#X auth  requisite      pam_deny.so
# prime the stack with a positive return value if there isn't one already;
# this avoids us returning an error just because nothing sets a success code
# since the modules above will each just jump around
auth  required      pam_permit.so
# and here are more per-package modules (the "Additional" block)
auth  optional      pam_cap.so 
# end of pam-auth-update config
PAM
    end
  end
  
  module Gre
    def self.prefix(path)
      "# this is a generated file do not edit!!!!!"
    end
    def self.build_config(host, iface)
#      binding.pry
      writer = host.result.delegate.etc_network_interfaces.get(iface)
      cfg = nil
      if iface.local.first_ipv6
        cfg = OpenStruct.new(:prefix=>6, :my=>iface.local.first_ipv6, :other => iface.remote.first_ipv6, :mode => "ip6gre") 
      elsif iface.local.first_ipv4
        cfg = OpenStruct.new(:prefix=>4, :my=>iface.local.first_ipv4, :other => iface.remote.first_ipv4, :mode => "ipgre") 
      end
      throw "need a local address #{host.name}:#{iface.name}" unless cfg
      iname = Util.clean_if("gt#{cfg.prefix}", iface.name)
      writer.header.interface_name = iname
      writer.lines.add(<<CFG)
up ip -#{cfg.prefix} tunnel add #{iname} mode #{cfg.mode} local #{cfg.my.to_s} remote #{cfg.other.to_s}
up ip -#{cfg.prefix} link set dev #{iname} up
down ip -#{cfg.prefix} tunnel del #{iname}
CFG
      Device.build_config(host, iface)
    end
  end

  module Template
    def self.prefix(path)
      "# this is a generated file do not edit!!!!!"
    end
    def self.build_config(host, iface)
    end
  end

  def self.clazz(name)
    ret = {
      "opvn" => Opvn, 
      "gre" => Gre, 
      "host" => Host, 
      "device"=> Device, 
      "vrrp" => Vrrp, 
      "bridge" => Bridge,
      "bond" => Bond, 
      "vlan" => Vlan,
      "result" => Result,
      "template" => Template
           }[name]
    throw "class not found #{name}" unless ret
    ret
  end
  def self.create_interface(name, cfg)
    cfg['name'] = name
    Interface.new(cfg)
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
