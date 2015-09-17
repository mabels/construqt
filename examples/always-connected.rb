
module AlwaysConnected

  def self.border_access(mother, ifname,  address)
    region = mother.region
    region.hosts.add("border-#{ifname}", "flavour" => "ubuntu", "mother" => mother,
                     "lxc_deploy" => [Construqt::Hosts::Lxc::RECREATE,Construqt::Hosts::Lxc::RESTART]) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
              "plug_in" => mother.interfaces.find_by_name("br666"),
              'address' => address.add_route_from_tags("#INTERNET", "#ROUTER", "metric" => 100))
      end
      region.interfaces.add_device(host, "border", "mtu" => 1500,
            "plug_in" => mother.interfaces.find_by_name(ifname),
            'address' => region.network.addresses.add_ip(Construqt::Addresses::DHCPV4))
    end
  end

  def self.mother(region)
    region.hosts.add("mother", "flavour" => "ubuntu") do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_bridge(host, "br666", "mtu" => 1500,
                                                              "interfaces" => [],
                     'address' => region.network.addresses.add_ip("169.254.69.1/24")
                                                          .add_ip("fd:a9fe:49::1/64")
                                    .add_route_from_tags("#INTERNET", "#ROUTER", "metric" => 100))
      end
      # hack das kommt dynamisch
      region.interfaces.add_device(host, "eth0", "mtu" => 1500)
      region.interfaces.add_device(host, "wlan0", "mtu" => 1500)
      region.interfaces.add_device(host, "wlan1", "mtu" => 1500)
    end

  end

  def self.router(mother)
    region = mother.region
    region.hosts.add("router", "flavour" => "ubuntu", "mother" => mother) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                     "plug_in" => mother.interfaces.find_by_name("br666"),
                     'address' => region.network.addresses.add_ip("169.254.69.8/24#ROUTER")
                                                          .add_ip("fd:a9fe:49::8/64#ROUTER"))
      end
    end
  end

  def self.access_controller(mother)
    region = mother.region
    region.hosts.add("access-ctl", "flavour" => "ubuntu", "mother" => mother) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                     "plug_in" => mother.interfaces.find_by_name("br666"),
                     'address' => region.network.addresses.add_ip("169.254.69.4/24")
                                                          .add_ip("fd:a9fe:49::4/64"))
      end
    end
  end

  def self.encrypter_region(mother, rname, address)
    region = mother.region
    region.hosts.add("tunnel-#{rname}", "flavour" => "ubuntu", "mother" => mother) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                     "plug_in" => mother.interfaces.find_by_name("br666"),
                     'address' => address)
      end
    end
  end

  def self.access_pointer(mother, rname, ifname, ssid, address)
    region = mother.region
    region.hosts.add("ap-#{rname}-#{ifname}", "flavour" => "ubuntu", "mother" => mother) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                     "plug_in" => mother.interfaces.find_by_name("br666"),
                     'address' => address)
      end
      region.interfaces.add_device(host, "wlan", "mtu" => 1500,
            "plug_in" => mother.interfaces.find_by_name(ifname),
            'address' => region.network.addresses.add_ip("172.25.69.0/24"))
    end
  end
end

