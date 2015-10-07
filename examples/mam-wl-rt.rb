
def mam_wl_rt(region)
  mam_wl_rt = region.hosts.add("mam-wl-rt", "flavour" => "ubuntu") do |host|
    region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                 :description=>"#{host.name} lo",
                                 "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
    eth0 = region.interfaces.add_device(host, "eth0", "mtu" => 1500)
    host.configip = host.id ||= Construqt::HostId.create do |my|
      my.interfaces << region.interfaces.add_bridge(host, "br0", "mtu" => 1500,
                               "interfaces" => [eth0],
                               "address" => region.network.addresses.add_ip("192.168.0.200/24")
                                                                    .add_route("0.0.0.0/0", "192.168.0.1"))
    end
    [202,203,204,205,206,207].each do |vlan|
      region.interfaces.add_bridge(host, "br#{vlan}", "mtu" => 1500,
                                   "interfaces" => [
                                    region.interfaces.add_vlan(host, "eth0.#{vlan}",
                                                     "vlan_id" => vlan,
                                                     "mtu" => 1500,
                                                     "interface" => eth0)])
    end
  end
  rts = {}
  [
    { :name => "rt-mam-wl-de", :block => 202 },
    { :name => "rt-mam-wl-de-6", :block => 203 },
    { :name => "rt-mam-us", :block => 204 },
    { :name => "rt-mam-de", :block => 205 },
    { :name => "rt-ab-us",  :block => 206 },
    { :name => "rt-ab-de",  :block => 207 }
  ].each do |net|
    rts[net[:name]] = region.hosts.add(net[:name], "flavour" => "ubuntu", "mother" => mam_wl_rt,
                                       "lxc_deploy" => [Construqt::Hosts::Lxc::RESTART]) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << my = region.interfaces.add_device(host, "v0", "mtu" => 1500,
              "plug_in" => Construqt::Cables::Plugin.new.iface(mam_wl_rt.interfaces.find_by_name("br0")),
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
  end
end
