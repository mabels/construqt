module Construqt
  module Flavour
    class Mikrotik
      class Host < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def footer(_host)
        end

        def self.header(delegate_host)
          host = delegate_host.delegate
          host.result.render_mikrotik_set_direct(
            {"contact" => Schema.string.required.key },
            {"contact" => "#{ENV['USER']}-#{`hostname`.strip}-#{`git  show --format=%h -q`.strip}-#{Time.now.to_i} <#{delegate_host.region.network.contact}>" }, "snmp")

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
                                                 { "time-zone-name" => host.time_zone||host.region.network.ntp.get_timezone },
                                                 "system", "clock")

          #/system ntp client> set secondary-ntp=2a04:2f80:2:1704::4711 primary-ntp=2a04:2f80:4:1706::4711
          host.result.render_mikrotik_set_direct({
                                                   "enabled" => Schema.boolean.default(true),
                                                   "primary-ntp"=> Schema.address.required.key,
                                                   "secondary-ntp"=> Schema.address.required.key
                                                 }, {
                                                   "primary-ntp" => host.region.network.ntp.servers.ips.first,
                                                   "secondary-ntp" => host.region.network.ntp.servers.ips.last
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
          host.result.add_remove_pre_condition('name!=default', "interface", "wireless", "security-profiles")
          host.result.add_remove_pre_condition('interface-type=virtual-AP', "interface", "wireless")
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

        def build_config(_host, _unused)
          ret = ["# host"]
        end
      end
    end
  end
end
