require 'pry'
require 'net/ssh'
require 'net/scp'

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'../../'
["#{CONSTRUQT_PATH}/ipaddress/lib","#{CONSTRUQT_PATH}/construqt/lib"].each{|path| $LOAD_PATH.unshift(path) }
require 'rubygems'
require 'construqt'

require_relative './firewall.rb'
begin
  require_relative './password.rb'
rescue LoadError
  require_relative './crashtestdummy.rb'
end

Construqt::Flavour::del_aspect("plantuml") unless ARGV.include?("plantuml")

network = Construqt::Networks.add('construqt')
network.set_domain("adviser.com")
network.set_contact("meno.abels.construqt.net")
network.set_dns_resolver(network.addresses.set_name("NAMESERVER").
                         add_ip("8.8.8.8").
                         add_ip("8.8.4.4"), [network.domain])
ipsec_certificate(network)

region = Construqt::Regions.add("winsen", network)

region.services.add(Construqt::Services::Radvd.new("RADVD").adv_autonomous)


region.users.add("menabe", "full_name" => "Meno Abels", "public_key" => <<KEY, "email" => "meno.abels@construqt.net")
ssh-dss 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 abels@nure
KEY

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

region.hosts.add("aiccu", "flavour" => "ubuntu") do |aiccu|
  region.interfaces.add_device(aiccu, "lo", "mtu" => "1500",
                               :description=>"#{aiccu.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

  region.interfaces.add_device(aiccu, "sixxs", "mtu" => "1280",
                               "dynamic" => true,
                               "firewalls" => [ fw_sixxs ],
                               "address" => region.network.addresses.add_ip("2001:6f8:900:2bf::2/64"))

  aiccu.configip = aiccu.id ||= Construqt::HostId.create do |my|
    my.interfaces << region.interfaces.add_device(aiccu, "eth0", "mtu" => 1500,
      "firewalls" => [ fw_outbound ],
      'address' => region.network.addresses.add_ip("192.168.67.2/24")
                                           .add_route("0.0.0.0/0", "192.168.67.1")
                                           .add_ip("2001:6f8:900:82bf::2/64"))
  end
end

fanout_de = region.hosts.add("fanout-de", "flavour" => "ubuntu") do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

  left_if = nil
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << left_if = region.interfaces.add_device(host, "eth0",
          "mtu" => 1500,
          'proxy_neigh' => Construqt::Tags.resolver_net("#SERVICE-TRANSIT#SERVICE-NET", Construqt::Addresses::IPV6),
          'address' => region.network.addresses.add_ip("78.47.4.51/29#FANOUT-DE")
                                            .add_route("0.0.0.0/0#INTERNET", "78.47.4.49")
                                            .add_ip("2a01:4f8:d15:1190:78:47:4:51/64")
                                            .add_route("2000::/3#INTERNET", "2a01:4f8:d15:1190::1"),
          "firewalls" => ["fix-mss", "host-outbound", "icmp-ping" , "ssh-srv", "ipsec-srv", "service-transit",
                          "service-nat", "service-smtp", "service-dns", "service-imap", "block"])
  end
  region.interfaces.add_ipsecvpn(host, "ipsec",
                              "mtu" => 1380,
                              "users" => ipsec_users,
                              "auth_internal" => :internal,
                              "left_interface" => left_if,
                              "leftpsk" => IPSEC_LEFT_PSK,
                              "leftcert" => region.network.cert_store.get_cert("fanout-de_adviser_com.crt"),
                              "right_address" => region.network.addresses.add_ip("192.168.69.64/26#IPSECVPN")
                                                                         .add_ip("2a01:4f8:d15:1190::cafe:0/112#IPSECVPN"),
                              "ipv6_proxy" => true)
  region.interfaces.add_bridge(host, "lxcbr",
    "mtu" => 1500,
    "interfaces" => [],
    "address" => region.network.addresses.add_ip("169.254.12.1/24"))

end


service_gw = region.hosts.add("service-gw", "flavour" => "ubuntu") do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
  region.network.addresses.add_ip("192.168.0.1/24#KDE-GW");
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << region.interfaces.add_device(host, "br24", "mtu" => 1500,
          'firewalls' => ['host-outbound', 'icmp-ping', 'ssh-srv', 'service-transit', 'block'],
          'address' => region.network.addresses.add_ip("192.168.0.66/24")
                                            .add_route("192.168.0.0/16", "192.168.0.10")
                                            .add_route_from_tags("#FANOUT-DE", "#KDE-GW"))
  end

  region.interfaces.add_device(host, "br66", "mtu" => 1500,
          'address' => region.network.addresses
                  .add_ip("192.168.66.1/24#SERVICE-NET")
                  .add_ip("2a01:4f8:d15:1190:192:168:66:1/123#SERVICE-NET"))
end


Construqt::Ipsecs.connection("#{fanout_de.name}<=>#{service_gw.name}",
          "password" => IPSEC_PASSWORD,
          "transport_family" => Construqt::Addresses::IPV4,
          "mtu_v4" => 1360,
          "mtu_v6" => 1360,
          "keyexchange" => "ikev2",
          "left" => {
            "my" => region.network.addresses.add_ip("169.254.66.1/30#SERVICE-IPSEC")
                      .add_ip("169.254.66.5/30#SERVICE-TRANSIT#FANOUT-DE-GW")
                      .add_ip("2a01:4f8:d15:1190::5/126#SERVICE-TRANSIT#FANOUT-DE-GW")
                      .add_route_from_tags("#SERVICE-NET", "#SERVICE-GW"),
            "host" => fanout_de,
            "remote" => region.interfaces.find(fanout_de, "eth0").address,
            "auto" => "add",
            "sourceip" => true
          },
          "right" => {
            "my" => region.network.addresses.add_ip("169.254.66.2/30")
                      .add_ip("169.254.66.6/30#SERVICE-GW")
                      .add_ip("2a01:4f8:d15:1190::6/126#SERVICE-TRANSIT#SERVICE-GW")
                      .add_route_from_tags("#INTERNET", "#FANOUT-DE-GW"),
            'firewalls' => ['host-outbound', 'icmp-ping', 'ssh-srv', 'service-transit',
                            "service-smtp", "service-dns", "service-imap", "service-radius", 'block'],
            "host" => service_gw,
            "remote" => region.interfaces.find(service_gw, "br24").address,
            "any" => true
          }
      )

['imap-ng', 'bind-ng', 'smtp-ng', 'ad'].each_with_index do |name, idx|
  region.hosts.add(name, "flavour" => "ubuntu") do |host|
    region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                 :description=>"#{host.name} lo",
                                 "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

    host.configip = host.id ||= Construqt::HostId.create do |my|
      my.interfaces << region.interfaces.add_device(host, "eth0",
            "mtu" => 1500,
            'address' => region.network.addresses.add_ip("192.168.66.#{10+idx}/24#HOST-#{name}")
                .add_route("0.0.0.0/0", "192.168.66.1")
                .add_ip("2a01:4f8:d15:1190:192:168:66:#{10+idx}/123#HOST-#{name}")
                .add_route("2000::/3", "2a01:4f8:d15:1190:192:168:66:1"))
    end
  end
end

fanout_us = region.hosts.add("fanout-us", "flavour" => "ubuntu") do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << region.interfaces.add_device(host, "eth0",
          "mtu" => 1500,
          'address' => region.network.addresses.add_ip("162.218.210.74/24#FANOUT-US")
                                            .add_route("0.0.0.0/0#INTERNET", "162.218.210.1")
                                            .add_ip("2602:ffea:1:7dd::eb38/44")
                                            .add_route("2000::/3#INTERNET", "2602:ffea:1::1"),
          "firewalls" => ["fix-mss", "host-us-outbound", "icmp-ping" , "ssh-srv", "ipsec-srv", "service-us-transit",
                          "service-us-nat", "block"])
  end
end

service_us = region.hosts.add("service-us", "flavour" => "ubuntu") do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "9000",
                               :description=>"#{host.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
  region.network.addresses.add_ip("192.168.0.1/24#KDE-GW");
  host.configip = host.id ||= Construqt::HostId.create do |my|
    my.interfaces << region.interfaces.add_device(host, "br24", "mtu" => 1500,
          'firewalls' => ['host-us-outbound', 'icmp-ping', 'ssh-srv', 'service-us-transit', 'block'],
          'address' => region.network.addresses.add_ip("192.168.0.68/24")
                                            .add_route("192.168.0.0/16", "192.168.0.10")
                                            .add_route_from_tags("#FANOUT-US", "#KDE-GW"))
  end

  region.interfaces.add_device(host, "br68", "mtu" => 1500,
          'address' => region.network.addresses
                  .add_ip("192.168.68.1/24#SERVICE-US-NET")
                  .add_ip("2602:ffea:1:7dd:192:168:68:1/123#SERVICE-US-NET"))
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

Construqt::Ipsecs.connection("#{fanout_us.name}<=>#{service_us.name}",
          "password" => IPSEC_PASSWORD,
          "transport_family" => Construqt::Addresses::IPV4,
          "mtu_v4" => 1360,
          "mtu_v6" => 1360,
          "keyexchange" => "ikev2",
          "left" => {
            "my" => region.network.addresses.add_ip("169.254.68.1/30#SERVICE-US-IPSEC")
                      .add_ip("169.254.68.5/30#SERVICE-US-TRANSIT#FANOUT-US-GW")
                      .add_ip("2602:ffea:1:7dd::5/126#SERVICE-US-TRANSIT#FANOUT-US")
                      .add_route_from_tags("#SERVICE-US-NET", "#SERVICE-US-GW"),
            "host" => fanout_us,
            "remote" => region.interfaces.find(fanout_us, "eth0").address,
            "auto" => "add",
            "sourceip" => true
          },
          "right" => {
            "my" => region.network.addresses.add_ip("169.254.68.2/30")
                      .add_ip("169.254.68.6/30#SERVICE-US-GW")
                      .add_ip("2602:ffea:1:7dd::6/126#SERVICE-US-TRANSIT#SERVICE-US-GW")
                      .add_route_from_tags("#INTERNET", "#FANOUT-US-GW"),
            'firewalls' => ['host-us-outbound', 'icmp-ping', 'ssh-srv', 'service-us-transit', 'block'],
            "host" => service_us,
            "remote" => region.interfaces.find(service_us, "br24").address,
            "any" => true
          }
      )


Construqt.produce(region)


if ARGV.include?("de")
  require 'net/ssh'
  require 'net/scp'
  ["fanout-us", "service-us", "fanout-de", "service-gw"].each do |hname|
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
