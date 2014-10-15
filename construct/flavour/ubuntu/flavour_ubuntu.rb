
require 'ostruct'
require 'construct/flavour/flavour.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_dns.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_ipsec.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_bgp.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_opvn.rb'
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
    def self.create_firewall(iface)
    end
    def self.add_address(host, iface)
      ret = []
      iface.address.ips.each do |ip|
        ret << "  up ip addr add #{ip.to_string} dev #{iface.name}"
        ret << "  down ip addr del #{ip.to_string} dev #{iface.name}"
      end
      iface.address.routes.each do |route|
        ret << "  up ip route add #{route.dst.to_string} via #{route.via.to_s}"
        ret << "  down ip route del #{route.dst.to_string} via #{route.via.to_s}"
      end
      create_firewall(iface)   
      ret << "  up iptables -t raw -A PREROUTING -i #{iface.name} -j NOTRACK"
      ret << "  up iptables -t raw -A OUTPUT -o #{iface.name} -j NOTRACK"
      ret << "  down iptables -t raw -D PREROUTING -i #{iface.name} -j NOTRACK"
      ret << "  down iptables -t raw -D OUTPUT -o #{iface.name} -j NOTRACK"
      ret << "  up ip6tables -t raw -A PREROUTING -i #{iface.name} -j NOTRACK"
      ret << "  up ip6tables -t raw -A OUTPUT -o #{iface.name} -j NOTRACK"
      ret << "  down ip6tables -t raw -D PREROUTING -i #{iface.name} -j NOTRACK"
      ret << "  down ip6tables -t raw -D OUTPUT -o #{iface.name} -j NOTRACK"
      ret
    end
    def self.build_config(host, iface)
      ret = ["auto #{iface.name}", "iface #{iface.name} inet manual"]
      ret << "  up ip link set mtu #{iface.mtu} dev #{iface.name} up"
      ret << "  down ip link set dev #{iface.name} down"
      ret += add_address(host, iface) unless iface.address.nil? || iface.address.ips.empty?
      host.result.add(self, ret.join("\n"), Ubuntu.root, "etc", "network", "interfaces")
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

#        host.result.add(<<BOND, "bond") 
#interface #{iface.name}
#channel-group #{i.name} mode active
#end
#BOND
      end
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
      Device.build_config(host, iface)
    end
  end
  module Host
    def self.prefix(path)
      "# this is a generated file do not edit!!!!!"
    end
    def self.build_config(host, unused)
      host.result.add(self, <<SCTL, Ubuntu.root, "etc", "sysctl.conf")
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
      Users.users.each do |u|
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
