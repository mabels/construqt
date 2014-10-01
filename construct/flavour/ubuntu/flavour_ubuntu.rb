
require 'ostruct'
require 'construct/flavour/flavour.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_dns.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_ipsec.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_bgp.rb'
require 'construct/flavour/ubuntu/flavour_ubuntu_opvn.rb'

module Construct
module Flavour
module Ubuntu
  def self.name
    'ubuntu'
  end
  Flavour.add(self)    

  def self.root
    OpenStruct.new :right => "0644", :owner => 'root'
  end

  def self.root_600
    OpenStruct.new :right => "0600", :owner => 'root'
  end

  def self.root_755
    OpenStruct.new :right => "0600", :owner => 'root'
  end
  
  class Result
    def initialize(host)
      @host = host
      @result = {}
    end
    def host
      @host
    end
    def empty?(name)
      not @result[name]
    end
    class ArrayWithRight < Array
      attr_accessor :right
      def initialize(right)
        self.right = right
      end
    end
    def add(clazz, block, right, *path)
      path = File.join(@host.name, *path)
      unless @result[path]
        @result[path] = ArrayWithRight.new(right)
        @result[path] << [clazz.header(path)]
      end
      @result[path] << block+"\n"
    end
    def commit
#      Net::SSH.start( HOST, USER, :password => PASS ) do|ssh| 
      @result.each do |name, block|
        #ssh = "ssh root@#{@host.configip.first_ipv4 || @host.configip.first_ipv6}"
        Util.write_str(block.join("\n"), name)
        #out << " mkdir -p #{File.dirname(name)}"
        #out << "scp #{name} "
        #out << "chown #{block.right.owner} #{name}"
        #out << "chmod #{block.right.right} #{name}"
      end
      #Util.write_str(out.join("\n"), @name, "deployer.sh")
    end
  end
  class Interface < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
    def build_config(host, unused)
      self.clazz.build_config(host, self)
    end
  end
  module Device
    def self.header(path)
      "# this is a generated file do not edit!!!!!"
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
    def self.header(path)
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
      throw "not implemented bond on ubuntu"
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
      throw "not implemented bridge on ubuntu"
    end
  end
  module Host
    def self.header(path)
      "# this is a generated file do not edit!!!!!"
    end
    def self.build_config(host, unused)
      host.result.add(self, <<SCTL, Ubuntu.root, "etc", "sysctl.conf")
net.ipv4.vs.pmtu_disc=1

net.ipv6.conf.all.autoconf=0
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.all.forwarding=1
SCTL
      host.result.add(self, host.name, host.name, "etc", "hostname")
      host.result.add(self, "# WTF resolvconf", host.name, "etc", "resolvconf", "resolv.conf.d", "orignal");
      host.result.add(self, <<RESOLVCONF,  host.name, "etc", "resolv.conf")
nameserver 2001:4860:4860::8844
nameserver 2001:4860:4860::8888
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
      host.result.add(self, ykeys.join("\n"), Ubuntu.root_600, "etc", "yubikey_mappings")

      host.result.add(self, <<PAM , Ubuntu.root_600, "etc", "pam.d", "common-auth")
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
    def self.header(path)
      "# this is a generated file do not edit!!!!!"
    end
    def self.build_config(host, iface)
    end
  end

  module Template
    def self.header(path)
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
