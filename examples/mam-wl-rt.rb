

def mam_actions(region)
  {
  "rt-ab-de" => lambda do |my, peers|
    fanout_de = peers[:de]
    Construqt::Ipsecs.connection("#{fanout_de.name}<=>#{my.name}",
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
              "host" => fanout_de,
              "remote" => region.interfaces.find(fanout_de, "eth0").address,
              "auto" => "add",
              "sourceip" => true
            },
            "right" => {
              "my" => region.network.addresses.add_ip("169.254.68.2/30")
                        .add_ip("169.254.68.6/30#SERVICE-GW-US")
                        .add_ip("2602:ffea:1:7dd::6/126#SERVICE-TRANSIT-US#SERVICE-GW-US")
                        .add_route_from_tags("#INTERNET", "#FANOUT-US-GW"),
              'firewalls' => ['host-us-outbound', 'icmp-ping', 'ssh-srv', 'service-us-transit', 'block'],
              "host" => my,
              "remote" => region.interfaces.find(my, "v24").address,
              "any" => true
            }
        )
  end,
  "rt-ab-us" => lambda do |my, peers|
    fanout_us = peers[:us]
    Construqt::Ipsecs.connection("#{fanout_us.name}<=>#{my.name}",
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
              "host" => my,
              "remote" => region.interfaces.find(my, "v24").address,
              "any" => true
            }
        )
    end
  }
end

def rt_mam_de()
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
end

def rt_mam_us()
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
end


def mam_wl_rt(region, peers)
  mam_wl_rt = region.hosts.add("mam-wl-rt", "flavour" => "ubuntu") do |host|
    region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                 :description=>"#{host.name} lo",
                                 "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
    eth0 = region.interfaces.add_device(host, "eth0", "mtu" => 1500)
    host.configip = host.id ||= Construqt::HostId.create do |my|
      my.interfaces << region.interfaces.add_bridge(host, "br24", "mtu" => 1500,
                               "interfaces" => [region.interfaces.add_vlan(host, "eth0.24",
                                                "vlan_id" => 24,
                                                "mtu" => 1500,
                                                "interface" => eth0)],
                               "address" => region.network.addresses.add_ip("192.168.0.200/24")
                                                                    .add_route("0.0.0.0/0", "192.168.0.1"))
    end
    # 66,67 service
    # 202-207 router
    [66,68,202,203,206,207].each do |vlan|
      region.interfaces.add_bridge(host, "br#{vlan}", "mtu" => 1500,
                                   "interfaces" => [
                                    region.interfaces.add_vlan(host, "eth0.#{vlan}",
                                                     "vlan_id" => vlan,
                                                     "mtu" => 1500,
                                                     "interface" => eth0)])
    end
  end
  rts = {}
  wifi_vlans = []
  region.hosts.add('mam-ap', "flavour" => "mikrotik") do |ap|
    wlan1 = region.interfaces.add_wlan(ap, "wlan1",
                                  "mtu" => 1500,
                                  "default_name" => "wlan1",
                                  "band" => "2ghz-b/g/n",
                                  "channel_width" => "20/40mhz-Ce",
                                  "country" => "germany",
                                  "mode" => "ap-bridge",
                                  "rx_chain" => "0,1",
                                  "tx_chain" => "0,1",
                                  "ssid" => Digest::SHA256.hexdigest("wlan1-germany-2ghz-b/g/n")[0..12],
                                  "psk" => Digest::SHA256.hexdigest(INTERNAL_PSK)[12..28],
                                  "hide_ssid" => true)

    wlan2 = region.interfaces.add_wlan(ap, "wlan2",
                                  "mtu" => 1500,
                                  "default_name" => "wlan2",
                                  "band" => "5ghz-a/n/ac",
                                  "channel_width" => "20/40/80mhz-Ceee",
                                  "country" => "germany",
                                  "frequency" => "auto",
                                  "frequency_mode" => "regulatory-domain",
                                  "mode" => "ap-bridge",
                                  "rx_chain" => "0,1,2",
                                  "tx_chain" => "0,1,2",
                                  "ssid" => Digest::SHA256.hexdigest("wlan1-germany-5ghz-a/n/ac")[0..12],
                                  "psk" => Digest::SHA256.hexdigest(INTERNAL_PSK)[12..28],
                                  "hide_ssid" => true)

    [
      { :name => "rt-mam-wl-de",   :block => 202 }, # homenet
      { :name => "rt-mam-wl-de-6", :block => 203 }, # aiccu
      { :name => "rt-mam-us",      :block => 68  }, # service-us
#      { :name => "rt-mam-de",      :block => 66  }, # service-de
      { :name => "rt-ab-us",       :block => 206 }, # airbnb-us
      { :name => "rt-ab-de",       :block => 207 }  # airbnb-de
    ].each do |net|
      if WIFI_PSKS[net[:name]]
        wifi_vlans += [
          {:freq => 24, :master_if => wlan1 },
          {:freq => 50, :master_if => wlan2 }
        ].map do |freq|
          ssid = "#{net[:name].sub(/^[a-zA-Z0-9]+-/,'')}-#{freq[:freq]}"
          simple_ssid = ssid.downcase.gsub(/[^0-9a-z]+/, '')
puts "#{ssid} => #{simple_ssid}"
          region.interfaces.add_wlan(ap, "wl#{simple_ssid}",
                                  "mtu" => 1500,
                                  "vlan_id" => net[:block],
                                  "master_if" => freq[:master_if],
                                  "ssid" => ssid.upcase,
                                  "psk" => WIFI_PSKS[net[:name]])
        end
      end

      rts[net[:name]] = region.hosts.add(net[:name], "flavour" => "ubuntu", "mother" => mam_wl_rt,
                                         "lxc_deploy" => [Construqt::Hosts::Lxc::RESTART]) do |host|
        region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                     :description=>"#{host.name} lo",
                                     "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
        host.configip = host.id ||= Construqt::HostId.create do |my|
          my.interfaces << region.interfaces.add_device(host, "v24", "mtu" => 1500,
                "plug_in" => Construqt::Cables::Plugin.new.iface(mam_wl_rt.interfaces.find_by_name("br24")),
                'firewalls' => ['host-outbound', 'icmp-ping', 'ssh-srv', 'service-transit', 'block'],
                'address' => region.network.addresses.add_ip("192.168.0.#{net[:block]}/24")
                                                     .add_route("0.0.0.0/24", "192.168.0.1"))
        end
        region.interfaces.add_device(host, "v#{net[:block]}", "mtu" => 1500,
              "plug_in" => Construqt::Cables::Plugin.new.iface(mam_wl_rt.interfaces.find_by_name("br#{net[:block]}")),
              'address' => region.network.addresses
                      .add_ip("192.168.#{net[:block]}.1/24#SERVICE-NET-DE-WL#SERVICE-NET-DE",
                              "dhcp_range" => ["192.168.#{net[:block]}.100", "192.168.#{net[:block]}.200"])
                      .add_ip("2a01:4f8:d15:1190:192:168:#{net[:block]}:1/123#SERVICE-NET-DE-WL#SERVICE-NET-DE"))
      end
      mam_actions(region)[net[:name]] && mam_actions(region)[net[:name]].call(rts[net[:name]], peers)
    end


    ether1 = region.interfaces.add_device(ap,  "ether1", "default_name" => "ether1")
    v66 =    region.interfaces.add_vlan(ap, "v66", "vlan_id" => 66,
              'address' => region.network.addresses
                                         .add_ip("192.168.66.5/24")
                                         .add_route("0.0.0.0/0", "192.168.66.1"))

    ap.configip = ap.id = Construqt::HostId.create do |my|
       my.interfaces << region.interfaces.add_bridge(ap, "bridge-local", "mtu" => 1500,
                                                     "interfaces" => [ether1,v66]+wifi_vlans)
    end
  end
end

