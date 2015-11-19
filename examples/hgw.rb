module Hgw
  def self.run(region, fanout_de)
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
  end
end
