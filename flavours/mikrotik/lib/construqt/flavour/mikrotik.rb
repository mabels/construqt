
require_relative 'mikrotik/schema.rb'
require_relative 'mikrotik/ipsec.rb'
require_relative 'mikrotik/bgp.rb'
require_relative 'mikrotik/result.rb'
require_relative 'mikrotik/interface.rb'


module Construqt
  module Flavour
    class Mikrotik
      def name
        "mikrotik"
      end

      class Factory
        def name
          'mikrotik'
        end
        def factory(cfg)
          FlavourDelegate.new(Mikrotik.new)
        end
      end

      Construqt::Flavour.add(Factory.new)

      class Device < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          binding.pry if iface.default_name.nil? || iface.default_name.empty?
          iface = iface.delegate
          default = {
            "l2mtu" => Schema.int.default(1590),
            "mtu" => Schema.int.default(1500),
            "name" => Schema.identifier.default("dummy"),
            "default-name" => Schema.identifier.required.key.noset
          }
          host.result.render_mikrotik_set_by_key(default, {
            "l2mtu" => iface.mtu,
            "mtu" => iface.mtu,
            "name" => iface.name,
            "default-name" => iface.default_name
          }, "interface")
          Interface.build_config(host, iface)
        end
      end

      class Wlan < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end
        def stereo_type
          self.master_if ? "WlanSlave" : "Wlan"
        end
        def wireless_security_profile(host, iface)
          default = {
            "authentication-types" => Schema.string.default("wpa-psk,wpa2-psk"),
            "management-protection" => Schema.identifier.default("allowed"),
            "mode" => Schema.identifier.default("dynamic-keys"),
            "supplicant-identity" => Schema.identifier.default(host.name),
            "name" => Schema.identifier.required.key,
            "wpa-pre-shared-key" => Schema.string.required,
            "wpa2-pre-shared-key" => Schema.string.required
          }
          host.result.render_mikrotik(default, {
            "authentication-types" => iface.authentication_types,
            "management-protection" => iface.management_protection,
            "mode" => iface.mode,
            "supplicant-identity" => iface.supplicant_identity,
            "name" => "sec-#{iface.name}",
            "wpa-pre-shared-key" => iface.psk,
            "wpa2-pre-shared-key" => iface.psk
          }, "interface", "wireless", "security-profiles")
        end
        def wireless_vap(host, iface)
          return unless iface.master_if
          default = {
            "mac-address" => Schema.string.required.key,
            "master-interface" => Schema.identifier.required,
            "name" => Schema.identifier.required.key,
            "security-profile" => Schema.identifier.required,
            "ssid" => Schema.identifier.required.key,
            "vlan-id" => Schema.int.required.key,
            "vlan-mode" => Schema.identifier.default("use-tag")
          }
          host.result.render_mikrotik(default, {
            "mac-address" => iface.mac_address || Construqt::Util.generate_mac_address_from_name(iface.ssid),
            "master-interface" => iface.master_if.name,
            "name" => iface.name,
            "security-profile" => "sec-#{iface.name}",
            "ssid" => iface.ssid,
            "vlan-id" => iface.vlan_id,
            "vlan-mode" => iface.vlan_mode
          }, "interface", "wireless")
        end
        def wireless_if(host, iface)
          return if iface.master_if
          default = {
            "default-name" => Schema.identifier.required.key,
            "band" => Schema.string.default("2ghz-B/G/N"),
            "channel-width" => Schema.string.default("20mhz"),
            "country" => Schema.string.default("germany"),
            "frequency" => Schema.string.default("auto"),
            "frequency-mode" => Schema.string.default("regulatory-domain"),
            "mode" => Schema.string.default("ap-bridge"),
            "rx-chain" => Schema.string.default("0"),
            "tx-chain" => Schema.string.default("0"),
            "ssid" => Schema.string.required,
            "psk" => Schema.string.required,
            "hide-ssid" => Schema.boolean.default(false)
          }
          host.result.render_mikrotik_set_by_key(default, {
            "default-name" => iface.default_name,
            "band" => iface.band,
            "channel-width" => iface.channel_width,
            "country" => iface.country,
            "frequency" => iface.frequency,
            "frequency-mode" => iface.frequency_mode,
            "mode" => iface.mode,
            "rx-chain" => iface.rx_chain,
            "tx-chain" => iface.tx_chain,
            "ssid" => iface.ssid,
            "psk" => iface.psk,
            "hide-ssid" => iface.hide_ssid
          }, "interface", "wireless")
        end
        def build_config(host, iface)
          #binding.pry if iface.default_name.nil? || iface.default_name.empty?
          iface = iface.delegate

          wireless_security_profile(host, iface)
          wireless_vap(host, iface)
          wireless_if(host, iface)

          Interface.build_config(host, iface)
        end
      end

      class Vrrp < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          iface = iface.delegate
          default = {
            "interface" => Schema.identifier.required,
            "name" => Schema.identifier.key.required,
            "priority" => Schema.int.required,
            "v3-protocol" => Schema.identifier.required,
            "vrid" => Schema.int.required
          }
          host.result.render_mikrotik(default, {
            "interface" => iface.interface.name,
            "name" => iface.name,
            "priority" => iface.interface.priority,
            "v3-protocol" => "ipv6",
            "vrid" => iface.vrid
          }, "interface", "vrrp")
          Interface.build_config(host, iface)
        end
      end

      class Bond < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def scheduler_hack(host, iface)
          #binding.pry if iface.name=="sw12"
          return [] unless iface.interfaces.find{|iface| iface.class.kind_of? self.class }

          system_script_schema = {
            "name" => Schema.identifier.key.required,
            "source" => Schema.source.required
          }
          host.result.render_mikrotik(system_script_schema, {
            "no_auto_disable" => true,
            "name" => "disable-#{iface.name}",
            "source" => <<SRC
/interface bonding disable [ find name=#{iface.name} ]
/system scheduler enable [ find name=enable-#{iface.name} ]
SRC
          }, "system", "script")

          or_condition = "(" + iface.interfaces.map{|iface| "name=#{iface.name}"}.join(" or ") + ")"
          host.result.render_mikrotik(system_script_schema, {
            "no_auto_disable" => true,
            "name" => "enable-#{iface.name}",
            "source" => <<SRC
:local run [ /interface bonding find running=yes and #{or_condition}]
:if ($run!="") do={
  /interface bonding enable [find name=sw12]
  /system schedule disable [ find name=enable-sw12 ]
}
SRC
          }, "system", "script")

          system_scheduler_script = {
            "name" => Schema.identifier.key.required,
            "on-event" => Schema.identifier.required,
            "start-time" => Schema.identifier.null,
            "interval" => Schema.interval.null,
            "disabled" => Schema.boolean.default(false)
          }
          host.result.render_mikrotik(system_scheduler_script, {
            "name" => "disable-#{iface.name}",
            "on-event" => "disable-#{iface.name}",
            "start-time" => "startup"
          }, "system", "scheduler")

          host.result.render_mikrotik(system_scheduler_script, {
            "name" => "enable-#{iface.name}",
            "on-event" => "enable-#{iface.name}",
            "interval" => "00:00:10",
            "disabled" => true
          }, "system", "scheduler")
        end

        def build_config(host, iface)
          iface = iface.delegate
          default = {
            "mode" => Schema.string.default("active-backup"),
            "mtu" => Schema.int.required,
            "name" => Schema.identifier.required.key,
            "slaves" => Schema.identifiers.required,
          }
          host.result.render_mikrotik(default, {
            "mtu" => iface.mtu,
            "name" => iface.name,
            "mode" => iface.mode,
            "slaves" => iface.interfaces.map{|iface| iface.name}.join(',')
          }, "interface", "bonding")
          Interface.build_config(host, iface)
          scheduler_hack(host, iface)
        end
      end

      class Vlan < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          iface = iface.delegate
          default = {
            "interface" => Schema.identifier.required,
            "mtu" => Schema.int.required,
            "name" => Schema.identifier.required.key,
            "vlan-id" => Schema.int.required,
          }
          iface.interfaces.each do |vlan_iface|
            host.result.render_mikrotik(default, {
              "interface" => vlan_iface.name,
              "mtu" => iface.mtu,
              "name" => iface.name,
              "vlan-id" => iface.vlan_id
            }, "interface", "vlan")
          end
          Interface.build_config(host, iface)
        end
      end

      class Bridge < OpenStruct
        include Construqt::Cables::Plugin::Multiple
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          iface = iface.delegate
          default = {
            "auto-mac" => Schema.boolean.default(true),
            "mtu" => Schema.int.required,
            "priority" => Schema.int.default(57344),
            "name" => Schema.identifier.required.key
          }
          host.result.render_mikrotik(default, {
            "mtu" => iface.mtu,
            "name" => iface.name,
            "priority" => iface.priority
          }, "interface", "bridge")
          iface.interfaces.each do |port|
            host.result.render_mikrotik({
              "bridge" => Schema.identifier.required.key,
              "interface" => Schema.identifier.required.key
            }, {
              "interface" => port.name,
              "bridge" => iface.name,
            }, "interface", "bridge", "port")
          end
          Interface.build_config(host, iface)
        end
      end

      class Host < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def footer(host)
        end

        def self.header(host)
          host = host.delegate
          host.result.add(<<TESTNAME, nil, "system", "identity")
{
  :local identity [get]
  :if (($identity->"name") != "#{host.name}") do={
    :put "Execute /system identity set name=#{host.name}"
    :error ("The Script is for router #{host.name} this router named ".($identity->"name"))
  } else={
    :put "Configure #{host.name}"
  }
}
TESTNAME
          host.result.render_mikrotik_set_direct({ "name"=> Schema.identifier.required.key },
                                                 { "name" => host.name }, "system", "identity")

          host.result.render_mikrotik_set_direct({ "time-zone-name"=> Schema.identifier.required.key },
                                                 { "time-zone-name" => host.time_zone||'MET' }, "system", "clock")

          #/system ntp client> set secondary-ntp=2a04:2f80:2:1704::4711 primary-ntp=2a04:2f80:4:1706::4711
          host.result.render_mikrotik_set_direct({
                                                   "enabled" => Schema.boolean.default(true),
                                                   "primary-ntp"=> Schema.address.required.key,
                                                   "secondary-ntp"=> Schema.address.required.key
                                                 }, {
                                                   "primary-ntp" => host.region.network.ntp_servers.ips.first,
                                                   "secondary-ntp" => host.region.network.ntp_servers.ips.last
                                                 }, "system", "ntp", "client")

          dns = host.region.network.dns_resolver.nameservers.ips
          host.result.render_mikrotik_set_direct({ "servers"=> Schema.addresses.required.key },
                                                 { "servers"=> dns }, "ip", "dns")

          host.result.add("add", nil, "tool", "graphing", "interface")

          host.result.add("set [ find name!=ssh && name!=www-ssl ] disabled=yes", nil, "ip", "service")
          host.result.add("set [ find ] address=0::/0", nil, "ip", "service")
          host.result.add("set [ find name!=admin ] comment=REMOVE", nil, "user")

          host.result.render_mikrotik({
            "name" => Schema.identifier.required.key,
            "enc-algorithms" => Schema.identifier.default("aes-256-cbc"),
            "lifetime" => Schema.interval.default("00:20:00"),
            "pfs-group"=> Schema.identifier.default("modp1536")
          }, {"name" => "s2b-proposal"}, "ip", "ipsec", "proposal")
          host.result.add("", "default=yes", "ip", "ipsec", "proposal")
          host.result.add("", "template=yes", "ip", "ipsec", "policy")
          host.result.add("", "name=default", "routing", "bgp", "instance")
          host.result.add_remove_pre_condition('comment~"CONSTRUQT\$"', "ip", "address")
          host.result.add_remove_pre_condition('comment~"CONSTRUQT\$"', "ip", "route")
          host.result.add_remove_pre_condition('comment~"CONSTRUQT\$"', "ipv6", "address")
          host.result.add_remove_pre_condition('comment~"CONSTRUQT\$"', "ipv6", "route")
          host.region.users.all.each do |u|
            host.result.add(<<OUT, nil, "user")
{
   :local found [find name=#{u.name.inspect} ]
   :if ($found = "") do={
       add comment=#{u.full_name.inspect} name=#{u.name} password=#{host.region.hosts.default_password} group=full
   } else={
     set $found comment=#{u.full_name.inspect}
   }
}
OUT
          end

          host.result.add("remove [find comment=REMOVE ]", nil, "user" )
          host.result.add("set [ find name=admin] disable=yes", nil, "user")
        end

        def build_config(host, unused)
          ret = ["# host"]
        end
      end

      class Ovpn < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          throw "ovpn not impl"
        end
      end

      class Gre < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def set_interface_gre(host, cfg)
          default = {
            "name"=>Schema.identifier.required.key,
            "local-address"=>Schema.address.required,
            "remote-address"=>Schema.address.required,
            "dscp"=>Schema.identifier.default("inherit"),
            "mtu"=>Schema.int.default(1476)
#            "l2mtu"=>Scheme.int.default(65535)
          }
          host.result.render_mikrotik(default, cfg, "interface", "gre")
        end

        def set_interface_gre6(host, cfg)
          default = {
            "name"=>Schema.identifier.required.key,
            "local-address"=>Schema.address.required,
            "remote-address"=>Schema.address.required,
            "keepalive" => Schema.identifiers.default(Schema::DISABLE),
            "mtu"=>Schema.int.default(1456)
#            "l2mtu"=>Schema.int.default(65535)
          }
          host.result.render_mikrotik(default, cfg, "interface", "gre6")
        end

        def build_config(host, iface)
          iface = iface.delegate
          #puts "iface.name=>#{iface.name}"
          #binding.pry
          #iname = Util.clean_if("gre6", "#{iface.name}")
          if iface.local.first_ipv6 && iface.remote.first_ipv6
            set_interface_gre6(host, "name"=> iface.name,
                               "local-address"=>iface.local.first_ipv6,
                               "remote-address"=>iface.remote.first_ipv6)
          else
            set_interface_gre(host, "name"=> iface.name,
                              "local-address"=>iface.local.first_ipv4,
                              "remote-address"=>iface.remote.first_ipv4)
          end
          Interface.build_config(host, iface)

          #Mikrotik.set_ipv6_address(host, "address"=>iface.address.first_ipv6.to_string, "interface" => iname)
        end
      end

      def set_ipv6_address(host, cfg)
        default = {
          "address"=>Schema.network.required,
          "interface"=>Schema.identifier.required,
          "comment" => Schema.string.required.key,
          "advertise"=>Schema.boolean.default(false)
        }
        cfg['comment'] = "#{cfg['interface']}-#{cfg['address']}"
        host.result.render_mikrotik(default, cfg, "ipv6", "address")
      end

      class Template < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
          throw "template not impl"
        end
      end

      def self.compress_address(val)
        return val.compressed if val.ipv4?
        found = 0
        val.groups.map do |i|
          if found > 0 && i != 0
            found = -1
          end

          if found == 0 && i == 0
            found += 1
            ""
          elsif found > 0 && i == 0
            found += 1
            nil
          else
            i.to_s 16
          end
        end.compact.join(":").sub(/:+$/, '::')
      end

      def ipsec
        Ipsec
      end

      def bgp
        Bgp
      end

      def clazzes
        {
          "opvn" => Ovpn,
          "gre" => Gre,
          "host" => Host,
          "device"=> Device,
          "vrrp" => Vrrp,
          "bridge" => Bridge,
          "bond" => Bond,
          "wlan" => Wlan,
          "vlan" => Vlan,
          #"result" => Result,
          "template" => Template,
          #"bgp" => Ipsec,
          #"ipsec" => Bgp
        }
      end
      def clazz(name)
        ret = self.clazzes[name]
        throw "class not found #{name}" unless ret
        ret
      end

      def create_host(name, cfg)
        cfg['name'] = name
        cfg['result'] = nil
        host = Host.new(cfg)
        host.result = Result.new(host)
        host
      end

      def create_interface(name, cfg)
        cfg['name'] = name
        clazz(cfg['clazz']).new(cfg)
      end

      def create_bgp(cfg)
        Bgp.new(cfg)
      end

      def create_ipsec(cfg)
        Ipsec.new(cfg)
      end
    end
  end
end
