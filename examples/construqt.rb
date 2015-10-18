require 'pry'
require 'net/ssh'
require 'net/scp'

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'../../'
[
  "#{CONSTRUQT_PATH}/ipaddress/lib",
  "#{CONSTRUQT_PATH}/construqt/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/plantuml/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ubuntu/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/mikrotik/lib"
].each{|path| $LOAD_PATH.unshift(path) }
require 'rubygems'
require 'construqt'

require_relative './firewall.rb'
if ARGV.include?("secure")
  require_relative './password.rb'
else
  require_relative './crashtestdummy.rb'
end

if ARGV.include?("plantuml")
  require 'construqt/flavour/plantuml.rb'
end

network = Construqt::Networks.add('construqt')
network.set_domain("adviser.com")
network.set_contact("meno.abels.construqt.net")
network.set_dns_resolver(network.addresses.set_name("NAMESERVER").
                         add_ip("8.8.8.8").
                         add_ip("8.8.4.4"), [network.domain])
ipsec_certificate(network)

region = Construqt::Regions.add("winsen", network)

region.network.add_ntp_server(region.network.addresses.add_ip("5.9.110.236").add_ip("178.23.124.2"))

region.services.add(Construqt::Services::Radvd.new("RADVD").adv_autonomous)


region.users.add("menabe", "group" => "admin", "full_name" => "Meno Abels", "public_key" => <<KEY, "email" => "meno.abels@construqt.net")
ssh-dss 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 abels@nure
KEY

region.network.addresses.add_ip("192.168.0.1/24#KDE-WL");

firewall(region)

fw_outbound = Construqt::Firewalls.add("fw-outbound") do |fw|
  fw.forward do |forward|
    forward.ipv6
    forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("@2000::/3").to_host("@2001:6f8:900:82bf:192:168:67:2").tcp.dport(22)
    forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("DEFAULT").from_is_outside
    forward.add.action(Construqt::Firewalls::Actions::DROP).log("FORWARD")
  end
  fw.host do |host|
    host.ipv6
    host.add.action(Construqt::Firewalls::Actions::ACCEPT).link_local
    host.add.action(Construqt::Firewalls::Actions::DROP).log('HOST')
  end
end

fw_sixxs = Construqt::Firewalls.add("fw-sixxs") do |fw|
  fw.forward do |forward|
    forward.ipv6
    forward.add.action(Construqt::Firewalls::Actions::TCPMSS)
  end
  fw.host do |host|
    host.ipv6
    host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("@2000::/3").to_me.tcp.dport(22).from_is_outside
    host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("@2000::/3").to_me.icmp.type(Construqt::Firewalls::ICMP::Ping).from_is_outside
    host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_me.to_net("@2000::/3")
    host.add.action(Construqt::Firewalls::Actions::DROP).log('HOST')
  end
end

region.network.addresses.add_ip("2000::/3#DEFAULT")


fanout_de = region.hosts.add("fanout-de", "flavour" => "ubuntu") do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

  left_if = nil
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << left_if = region.interfaces.add_device(host, "eth0",
          "mtu" => 1500,
          'proxy_neigh' => Construqt::Tags.resolver_net("#SERVICE-TRANSIT-DE#SERVICE-NET-DE", Construqt::Addresses::IPV6),
          'address' => region.network.addresses.add_ip("78.47.4.51/29#FANOUT-DE")
                                            .add_route("0.0.0.0/0#INTERNET", "78.47.4.49")
                                            .add_ip("2a01:4f8:d15:1190:78:47:4:51/64")
                                            .add_route("2000::/3#INTERNET", "2a01:4f8:d15:1190::1"),
          "firewalls" => ["fix-mss", "host-outbound", "icmp-ping" , "ssh-srv", "ipsec-srv", "service-ssh-hgw",
                          "service-transit",
                          "service-nat", "service-smtp", "service-dns", "service-imap", "vpn-server-net", "block"])
  end
  region.interfaces.add_ipsecvpn(host, "roadrunner",
                              "mtu" => 1380,
                              "users" => ipsec_users,
                              "auth_method" => :internal,
                              "left_interface" => left_if,
                              "leftpsk" => IPSEC_LEFT_PSK,
                              "leftcert" => region.network.cert_store.get_cert("fanout-de_adviser_com.crt"),
                              "right_address" => region.network.addresses.add_ip("192.168.72.64/26#IPSECVPN-DE")
                                                                         .add_ip("2a01:4f8:d15:1190::cafe:0/112#IPSECVPN-DE"),
                              "ipv6_proxy" => true)
  region.interfaces.add_bridge(host, "br12",
    "mtu" => 1500,
    "interfaces" => [],
    "address" => region.network.addresses.add_ip("169.254.12.1/24#FANOUT-DE-BACKEND#FANOUT-DE-BR12")
                                         .add_ip("2a01:4f8:d15:1190:169:254:12:1/123#FANOUT-DE-BACKEND"))

end


fanout_us = region.hosts.add("fanout-us", "flavour" => "ubuntu") do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

  left_if = nil
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << left_if = region.interfaces.add_device(host, "eth0",
          "mtu" => 1500,
          'address' => region.network.addresses.add_ip("162.218.210.74/24#FANOUT-US")
                                            .add_route("0.0.0.0/0#INTERNET", "162.218.210.1")
                                            .add_ip("2602:ffea:1:7dd::eb38/44")
                                            .add_route("2000::/3#INTERNET", "2602:ffea:1::1"),
          "firewalls" => ["fix-mss", "host-us-outbound", "icmp-ping" , "ssh-srv", "ipsec-srv", "service-us-transit",
                          "service-us-nat", "block"])
  end
  region.interfaces.add_ipsecvpn(host, "roadrunner",
                              "mtu" => 1380,
                              "users" => ipsec_users,
                              "auth_method" => :internal,
                              "left_interface" => left_if,
                              "leftpsk" => IPSEC_LEFT_PSK,
                              "leftcert" => region.network.cert_store.get_cert("fanout-us_adviser_com.crt"),
                              "right_address" => region.network.addresses.add_ip("192.168.71.64/26#IPSECVPN-US")
                                                                         .add_ip("2602:ffea:1:7dd::cafe:0/112#IPSECVPN-US"),
                              "ipv6_proxy" => true)

  region.interfaces.add_bridge(host, "br13",
    "mtu" => 1500,
    "interfaces" => [],
    "address" => region.network.addresses.add_ip("169.254.13.1/24#FANOUT-US-BACKEND#FANOUT-US-BR13"))

end

scott = region.hosts.add("scott", "flavour" => "ubuntu") do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
  eth0 = region.interfaces.add_device(host, "eth0", "mtu" => 1500)
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << region.interfaces.add_bridge(host, "br0", "mtu" => 1500,
                               "interfaces" => [eth0],
                               "address" => region.network.addresses.add_ip("192.168.176.1/24")
                                                                    .add_route("0.0.0.0/0", "192.168.176.4"))
  end
  [24,66,67,68].each do |vlan|
    region.interfaces.add_bridge(host, "br#{vlan}", "mtu" => 1500,
                                 "interfaces" => [
                                  region.interfaces.add_vlan(host, "eth0.#{vlan}",
                                                   "vlan_id" => vlan,
                                                   "mtu" => 1500,
                                                   "interface" => eth0)])
  end
end

service_us = region.hosts.add("service-us", "flavour" => "ubuntu", "mother" => scott) do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << my = region.interfaces.add_device(host, "br24", "mtu" => 1500,
          'firewalls' => ['host-us-outbound', 'icmp-ping', 'ssh-srv', 'service-us-transit', 'block'],
          'address' => region.network.addresses.add_ip("192.168.0.68/24")
                                            .add_route("192.168.0.0/16", "192.168.0.10")
                                            .add_route_from_tags("#FANOUT-US", "#KDE-WL"))
    region.cables.add(my, region.interfaces.find("scott", "br24"))
  end

  region.cables.add(
    region.interfaces.add_device(host, "br68", "mtu" => 1500,
          'address' => region.network.addresses
                  .add_ip("192.168.68.1/24#SERVICE-NET-US")
                  .add_ip("2602:ffea:1:7dd:192:168:68:1/123#SERVICE-NET-US")),
   region.interfaces.find("scott", "br68"))
end


service_de_wl = region.hosts.add("service-de-wl", "flavour" => "ubuntu", "mother" => scott) do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << my = region.interfaces.add_device(host, "br24", "mtu" => 1500,
          'firewalls' => ['host-outbound', 'icmp-ping', 'ssh-srv', 'service-transit', 'block'],
          'address' => region.network.addresses.add_ip("192.168.0.66/24")
                                            .add_route("192.168.0.0/16", "192.168.0.10")
                                            .add_route_from_tags("#FANOUT-DE", "#KDE-WL"))
    region.cables.add(my, region.interfaces.find("scott", "br24"))
  end

  region.cables.add(
    region.interfaces.add_device(host, "br66", "mtu" => 1500,
          'address' => region.network.addresses
                  .add_ip("192.168.66.1/24#SERVICE-NET-DE-WL#SERVICE-NET-DE")
                  .add_ip("192.168.69.1/24#SERVICE-NET-US")
                  .add_ip("2a01:4f8:d15:1190:192:168:66:1/123#SERVICE-NET-DE-WL#SERVICE-NET-DE")
                  .add_ip("2602:ffea:1:7dd:192:168:66:1/123#SERVICE-NET-US")),
   region.interfaces.find("scott", "br66"))
end


Construqt::Ipsecs.connection("#{fanout_de.name}<=>#{service_de_wl.name}",
          "password" => IPSEC_PASSWORD,
          "transport_family" => Construqt::Addresses::IPV4,
          "mtu_v4" => 1360,
          "mtu_v6" => 1360,
          "keyexchange" => "ikev2",
          "left" => {
            "my" => region.network.addresses.add_ip("169.254.66.1/30#SERVICE-IPSEC")
                      .add_ip("169.254.66.5/30#SERVICE-TRANSIT-DE#FANOUT-DE-WL-GW")
                      .add_ip("2a01:4f8:d15:1190::5/126#SERVICE-TRANSIT-DE#FANOUT-DE-WL-GW")
                      .add_route_from_tags("#SERVICE-NET-DE-WL", "#SERVICE-DE-WL"),
            "host" => fanout_de,
            "remote" => region.interfaces.find(fanout_de, "eth0").address,
            "auto" => "add",
            "sourceip" => true
          },
          "right" => {
            "my" => region.network.addresses.add_ip("169.254.66.2/30")
                      .add_ip("169.254.66.6/30#SERVICE-DE-WL#SERVICE-NET-DE")
                      .add_ip("2a01:4f8:d15:1190::6/126#SERVICE-TRANSIT-DE#SERVICE-DE-WL#SERVICE-NET-DE")
                      .add_route_from_tags("#INTERNET", "#FANOUT-DE-WL-GW"),
            'firewalls' => ['host-outbound', 'icmp-ping', 'ssh-srv', 'service-transit',
                            "service-smtp", "service-dns", "service-imap", "service-ad", "vpn-server-net", 'block'],
            "host" => service_de_wl,
            "remote" => region.interfaces.find(service_de_wl, "br24").address,
            "any" => true
          }
      )


['imap-ng', 'bind-ng', 'smtp-ng', 'ad'].each_with_index do |name, idx|
  region.hosts.add(name, "flavour" => "ubuntu", "mother" => scott) do |host|
    region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                 :description=>"#{host.name} lo",
                                 "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

    host.configip = host.id ||= Construqt::HostId.create do |my|
      my.interfaces << iface = region.interfaces.add_device(host, "eth0",
            "mtu" => 1500,
            'address' => region.network.addresses
                .add_ip("192.168.66.#{10+idx}/24#HOST-#{name}")
                .add_ip("192.168.69.#{10+idx}/24")
                .add_route("0.0.0.0/0", "192.168.66.1")
                .add_ip("2a01:4f8:d15:1190:192:168:66:#{10+idx}/123#HOST-#{name}")
                .add_ip("2602:ffea:1:7dd:192:168:66:#{10+idx}/123")
                .add_route("2000::/3", "2a01:4f8:d15:1190:192:168:66:1"))
      region.cables.add(iface, region.interfaces.find("scott", "br66"))
    end
  end
end

['smtp-de', 'bind-de'].each_with_index do |name, idx|
  region.hosts.add(name, "flavour" => "ubuntu", "mother" => fanout_de) do |host|
    region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                 :description=>"#{host.name} lo",
                                 "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

    host.configip = host.id ||= Construqt::HostId.create do |my|
      my.interfaces << iface = region.interfaces.add_device(host, "eth0",
            "mtu" => 1500,
            'address' => region.network.addresses
                .add_ip("169.254.12.#{10+idx}/24#HOST-#{name}#SERVICE-NET-DE")
                .add_route("0.0.0.0/0", "169.254.12.1")
                .add_ip("2a01:4f8:d15:1190:169:254:12:#{10+idx}/123#HOST-#{name}#SERVICE-NET-DE")
                .add_route("2000::/3", "2a01:4f8:d15:1190:169:254:12:1"))
      region.cables.add(iface, region.interfaces.find("fanout-de", "br12"))
    end
  end
end

['smtp-us', 'bind-us'].each_with_index do |name, idx|
  region.hosts.add(name, "flavour" => "ubuntu", "mother" => fanout_us) do |host|
    region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                 :description=>"#{host.name} lo",
                                 "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

    host.configip = host.id ||= Construqt::HostId.create do |my|
      my.interfaces << iface = region.interfaces.add_device(host, "eth0",
            "mtu" => 1500,
            'address' => region.network.addresses
                .add_ip("169.254.13.#{10+idx}/24#HOST-#{name}")
                .add_route("0.0.0.0/0", "169.254.13.1")
                .add_ip("2a01:4f8:d15:1190:169:254:13:#{10+idx}/123#HOST-#{name}")
                .add_route("2000::/3", "2a01:4f8:d15:1190:169:254:13:1"))
      region.cables.add(iface, region.interfaces.find("fanout-us", "br13"))
    end
  end
end


region.hosts.add("aiccu", "flavour" => "ubuntu", "mother" => scott) do |aiccu|
  region.interfaces.add_device(aiccu, "lo", "mtu" => "1500",
                               :description=>"#{aiccu.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

  region.interfaces.add_device(aiccu, "sixxs", "mtu" => "1280",
                               "dynamic" => true,
                               "firewalls" => [ fw_sixxs ],
                               "address" => region.network.addresses.add_ip("2001:6f8:900:2bf::2/64"))

  aiccu.configip = aiccu.id ||= Construqt::HostId.create do |my|
    my.interfaces << iface = region.interfaces.add_device(aiccu, "eth0", "mtu" => 1500,
      "firewalls" => [ fw_outbound ],
      'address' => region.network.addresses.add_ip("192.168.67.2/24")
                                           .add_route("0.0.0.0/0", "192.168.67.1")
                                           .add_ip("2001:6f8:900:82bf::2/64"))
    region.cables.add(iface, region.interfaces.find("scott", "br67"))
  end
end

kuckpi = region.hosts.add("kuckpi", "flavour" => "ubuntu") do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
  eth0 = region.interfaces.add_device(host, "eth0", "mtu" => 1500)
  wlan0 = region.interfaces.add_wlan(host, "wlan0", "mtu" => 1500, "ssid" => "VALADON-2", "psk" => VALADON_PSK)
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << region.interfaces.add_bridge(host, "br0", "mtu" => 1500,
                               "interfaces" => [eth0, wlan0],
                               "address" => region.network.addresses.add_ip("192.168.178.14/24")
                                                                    .add_route("0.0.0.0/0", "192.168.178.1"))
  end
  [{:vlan=>24} ,{:vlan=>70, :address=>region.network.addresses.add_ip("192.168.70.14/24")}].each do |vlan|
    region.interfaces.add_bridge(host, "br#{vlan[:vlan]}", "mtu" => 1500,
                                 "interfaces" => [
                                  region.interfaces.add_vlan(host, "eth0.#{vlan[:vlan]}",
                                                   "vlan_id" => vlan[:vlan],
                                                   "mtu" => 1500,
                                                   "address" => vlan[:address],
                                                   "interface" => eth0)])
  end
end

service_de_hgw = region.hosts.add("service-de-hgw", "flavour" => "ubuntu", "mother" => kuckpi) do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
  region.network.addresses.add_ip("192.168.178.1/24#KDE-HGW");
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << iface = region.interfaces.add_device(host, "br0", "mtu" => 1500,
          'firewalls' => ['host-outbound', 'icmp-ping', 'ssh-srv', 'service-transit', "vpn-server-net", 'block'],
          'address' => region.network.addresses.add_ip("192.168.178.15/24")
                                            .add_route_from_tags("#FANOUT-DE", "#KDE-HGW"))
      region.cables.add(iface, region.interfaces.find(kuckpi, 'br0'))
  end

  region.cables.add(region.interfaces.add_device(host, "br70", "mtu" => 1500,
          'address' => region.network.addresses
                  .add_ip("192.168.70.1/24#SERVICE-NET-DE-HGW#SERVICE-NET-DE")
                  .add_ip("2a01:4f8:d15:1190:192:168:70:1/123#SERVICE-NET-DE-HGW#SERVICE-NET-DE")),
          region.interfaces.find(kuckpi, 'br70'))
end


Construqt::Ipsecs.connection("#{fanout_de.name}<=>#{service_de_hgw.name}",
          "password" => IPSEC_PASSWORD,
          "transport_family" => Construqt::Addresses::IPV4,
          "mtu_v4" => 1360,
          "mtu_v6" => 1360,
          "keyexchange" => "ikev2",
          "left" => {
            "my" => region.network.addresses.add_ip("169.254.70.1/30#SERVICE-IPSEC")
                      .add_ip("169.254.70.5/30#SERVICE-TRANSIT-DE#FANOUT-DE-HGW-GW")
                      .add_ip("2a01:4f8:d15:1190::9/126#SERVICE-TRANSIT-DE#FANOUT-DE-HGW-GW")
                      .add_route_from_tags("#SERVICE-NET-DE-HGW", "#SERVICE-DE-HGW"),
            "host" => fanout_de,
            "remote" => region.interfaces.find(fanout_de, "eth0").address,
            "auto" => "add",
            "sourceip" => true
          },
          "right" => {
            "my" => region.network.addresses.add_ip("169.254.70.2/30")
                      .add_ip("169.254.70.6/30#SERVICE-DE-HGW#SERVICE-NET-DE")
                      .add_ip("2a01:4f8:d15:1190::a/126#SERVICE-TRANSIT-DE#SERVICE-DE-HGW#SERVICE-NET-DE")
                      .add_route_from_tags("#INTERNET", "#FANOUT-DE-HGW-GW"),
            'firewalls' => ['host-outbound', 'icmp-ping', 'ssh-srv', 'service-transit', 'block'],
            "host" => service_de_hgw,
            "remote" => region.interfaces.find(service_de_hgw, "br0").address,
            "any" => true
          }
      )

kucksdu = region.hosts.add("kucksdu", "flavour" => "ubuntu") do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << region.interfaces.add_device(host, "eth0", "mtu" => 1500,
                               "address" => region.network.addresses.add_ip("192.168.178.18/24")
                                                                    .add_route("0.0.0.0/0", "192.168.178.1"))
  end
end

Construqt::Ipsecs.connection("#{fanout_us.name}<=>#{service_us.name}",
          "password" => IPSEC_PASSWORD,
          "transport_family" => Construqt::Addresses::IPV4,
          "mtu_v4" => 1360,
          "mtu_v6" => 1360,
          "keyexchange" => "ikev2",
          "left" => {
            "my" => region.network.addresses.add_ip("169.254.68.1/30#SERVICE-IPSEC-US")
                      .add_ip("169.254.68.5/30#SERVICE-TRANSIT-US#FANOUT-US-GW")
                      .add_ip("2602:ffea:1:7dd::5/126#SERVICE-TRANSIT-US#FANOUT-US")
                      .add_route_from_tags("#SERVICE-NET-US", "#SERVICE-GW-US"),
            "host" => fanout_us,
            "remote" => region.interfaces.find(fanout_us, "eth0").address,
            "auto" => "add",
            "sourceip" => true
          },
          "right" => {
            "my" => region.network.addresses.add_ip("169.254.68.2/30")
                      .add_ip("169.254.68.6/30#SERVICE-GW-US")
                      .add_ip("2602:ffea:1:7dd::6/126#SERVICE-TRANSIT-US#SERVICE-GW-US")
                      .add_route_from_tags("#INTERNET", "#FANOUT-US-GW"),
            'firewalls' => ['host-us-outbound', 'icmp-ping', 'ssh-srv', 'service-us-transit', 'block'],
            "host" => service_us,
            "remote" => region.interfaces.find(service_us, "br24").address,
            "any" => true
          }
      )


[
  {:name => 'ad-de', :address => "169.254.12.10/24", :gw => "#FANOUT-DE-BR12", "mother" => fanout_de, "plug" => "br12" },
  {:name => 'ad-us', :address => "169.254.13.10/24", :gw => "#FANOUT-US-BR13", "mother" => fanout_us, "plug" => "br13" }
].map{|i| OpenStruct.new(i) }.each do |cfg|
  region.hosts.add(cfg.name, "flavour" => "ubuntu", "mother" => cfg['mother']) do |host|
    region.interfaces.add_device(host, "lo", "mtu" => "1500",
                                 :description=>"#{host.name} lo",
                                 "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

    host.configip = host.id ||= Construqt::HostId.create do |my|
      my.interfaces << iface = region.interfaces.add_device(host, "eth0", "mtu" => 1500,
                 'address' => region.network.addresses.add_ip("#{cfg.address}#HOST-#{cfg.name}")
                                                       .add_route_from_tags("#INTERNET", cfg.gw))
      region.cables.add(iface, region.interfaces.find(cfg['mother'], cfg['plug']))
    end
  end
end

dvb_link = region.hosts.add("dvb-link", "flavour" => "ubuntu", "mother" => kuckpi) do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << iface = region.interfaces.add_device(host, "eth0", "mtu" => 1500,
          'address' => region.network.addresses.add_ip("192.168.178.16/24")
                                .add_route_from_tags("#INTERNET", "#KDE-HGW"))
    region.cables.add(iface, region.interfaces.find("kuckpi", "br0"))
  end
end

armhf = region.hosts.add("armhf", "flavour" => "ubuntu", "mother" => fanout_de) do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << iface = region.interfaces.add_device(host, "eth0", "mtu" => 1500,
                   'address' => region.network.addresses.add_ip("169.254.12.17/24")
                                .add_route("0.0.0.0/0", "169.254.12.1"))
    region.cables.add(iface, region.interfaces.find("fanout-de", "br12"))
  end
end

fbsd = region.hosts.add("fbsd", "flavour" => "nixian", "dialect" => "ubuntu", "mother" => scott) do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << my = region.interfaces.add_device(host, "vtnet0", "mtu" => 1500,
          'address' => region.network.addresses.add_ip("192.168.176.19/24")
      .add_route_from_tags("#INTERNET", "192.168.176.4"))
    region.cables.add(my, region.interfaces.find("scott", "br0"))
  end
end


#mam_5ghz = region.hosts.add("mam-5ghz", "flavour" => "mikrotik") do |host|
#  ether1_local = region.interfaces.add_device(host, "ether1_local", "mtu" => "1500")
#  wlan1_gateway = region.interfaces.add_device(host, "wlan1-gateway", "mtu" => "1500")
#  [
#    {:vlan=>24, :name => "uplink", :address => region.network.addresses.add_ip("192.168.0.5/24").add_route("0.0.0.0/0", "192.168.0.1")},
#    {:vlan=>66, :name => "hetzner", :ssid => "MAM-50-HET" },
#    {:vlan=>67, :name => "homede-ipv6", :ssid => "MAM-50-DEIPV"},
#    {:vlan=>68, :name => "homeus", :ssid => "MAM-50-US"},
#    {:vlan=>73, :name => "abus", :ssid => "AB-50-US"},
#    {:vlan=>74, :home => "abde", :ssid => "AB-50-DE"},
#    {:vlan=>176, :home => "homede", :ssid => "MAM-50-DE"},
#  ].each do |vlan|
#    region.interfaces.add_bridge(host, "br-#{vlan[:vlan]}-#{vlan[:name]}",
#                                       "mtu" => 1500,
#                                       "address" => vlan[:address]
#                                       "interfaces" => [
#       region.interfaces.add_vlan("ve-#{vlan[:vlan]}-#{vlan[:name]}", "vlan_id" => vlan[:vlan], "mtu" => 1500, "interface" => ether1_local)
#       region.interfaces.add_wlan("wl-#{vlan[:vlan]}-#{vlan[:name]}", "mode" => "ap", "ssid" => vlan[:ssid], "psk" => MAM_PSK,
#                                  "mtu" => 1500, "interface" => wlan1-gateway)
#    ],
#  end
#    region.interfaces.add_device(host, "lo", "mtu" => "9000",
#                                                                :description=>"#{host.name} lo",
#                                                                                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
#      host.configip = host.id ||= Construqt::HostId.create do |my|
#            my.interfaces << my = region.interfaces.add_device(host, "vtnet0", "mtu" => 1500,
#                                                                         'address' => region.network.addresses.add_ip("192.168.176.19/24")
#                  .add_route_from_tags("#INTERNET", "192.168.176.4"))
#                region.cables.add(my, region.interfaces.find("scott", "br0"))
#                  end
#end


require_relative "./always-online.rb"

mother = AlwaysConnected.mother(region)

AlwaysConnected.border_access(mother, "eth0")
AlwaysConnected.border_access(mother, "wlan0")
AlwaysConnected.border_access(mother, "usb0")
AlwaysConnected.border_access(mother, "usbnet0")

AlwaysConnected.router(mother)
AlwaysConnected.access_controller(mother)

AlwaysConnected.access_pointer(mother, "de", "wlan1", "MAM-AL-DE",
                               region.network.addresses.add_ip("169.254.69.65/24")
                                                       .add_ip("fd:a9fe:49::65/64"))

AlwaysConnected.encrypter_region(mother, "de", region.network.addresses.add_ip("169.254.69.97/24")
                                                               .add_ip("fd:a9fe:49::97/64"))


#AlwaysConnected.access_pointer(mother, "de", "wlan2", "MAM-AL-US",
#                               region.network.addresses.add_ip("169.254.69.66/24")
#                                                       .add_ip("fd:a9fe:49::66/64"))
require_relative "./mam-wl-rt.rb"

mam_wl_rt(region, {:de => fanout_de, :us => fanout_us})


Construqt.produce(region)


if ARGV.include?("de")
  require 'net/ssh'
  require 'net/scp'
  ["fanout-us", "service-us", "fanout-de", "service-de-wl", "service-de-hgw"].each do |hname|
    host = region.hosts.find(hname)
    dest = host.id.first_ipv4.first_ipv4.to_s
    Construqt.logger.info "Copy deployer.sh to #{host.name}(#{dest})"
    Net::SCP.upload!(dest, 'root', "cfgs/#{host.name}/deployer.sh", "/root/deployer.sh")
    Net::SSH.start(dest.to_s, 'root' ) do |ssh|
      ssh.exec('bash /root/deployer.sh') do |ch, stream, data|
        puts data
      end
    end
  end
end
