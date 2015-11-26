
module AlwaysConnected
  BORDER_ACCESS = []

  def self.ac_router(region, name, block, fws, mother)
    region.hosts.add(name, "flavour" => "nixian", "dialect" => "ubuntu", "mother" => mother,
                     "lxc_deploy" => Construqt::Hosts::Lxc.new.aa_profile_unconfined.restart.killstop.release("wily")) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << region.interfaces.add_device(host, "br666", "mtu" => 1500,
                                                      "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name("br666")),
                                                      'firewalls' => fws + ['service-transit-local', 'ssh-srv', 'icmp-ping', 'block'],
                                                      'address' => region.network.addresses.add_ip("169.254.69.#{block}/24")
          .add_route("0.0.0.0/0", "169.254.69.1"))
      end
      #region.interfaces.add_bridge(mother, "br#{block}", "mtu" => 1500, "interfaces" => [
      #  region.interfaces.add_vlan(mother, "eth0.#{block}", "mtu" => 1580, "vlan_id" => block, "interface" => mother.interfaces.find_by_name("eth0"))
      #])
      region.interfaces.add_vlan(host, "eth0.#{block}", "mtu" => 1580, "vlan_id" => block, "interface" =>
        region.interfaces.add_device(host, "eth0", "mtu" => 1500,
                  "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name("br0"))),
                                    'address' => region.network.addresses.add_ip("172.23.#{block}.1/24#NET-#{name}",
                                    "dhcp" => Construqt::Dhcp.new.start("172.23.#{block}.100").end("172.23.#{block}.200").domain(name)))
    end
  end

  def self.mam_otr(mother)
    region = mother.region
    wifi_vlans = []
    region.hosts.add('mam-otr', "flavour" => "mikrotik") do |ap|
      wlan1 = region.interfaces.add_wlan(ap, "wlan1",
                                         "mtu" => 1500,
                                         "default_name" => "wlan1",
                                         "band" => "2ghz-b/g/n",
                                         "channel_width" => "20/40mhz-Ce",
                                         "country" => "france",
                                         "mode" => "ap-bridge",
                                         "rx_chain" => "0,1",
                                         "tx_chain" => "0,1",
                                         "ssid" => Digest::SHA256.hexdigest("wlan1-france-2ghz-b/g/n")[0..12],
                                         "psk" => Digest::SHA256.hexdigest(INTERNAL_PSK)[12..28],
                                         "hide_ssid" => true)
      [
        { :name => "ao-ac-mam-otr",    :fws => ['net-nat', "net-forward"], :ssid => "MAM-OTR",    :block => 123 }, # homenet
        { :name => "ao-ac-mam-otr-de", :fws => ['net-nat', "net-forward"], :ssid => "MAM-OTR-DE", :ipsec => Resolv.getaddress("fanout-de.adviser.com"), :block => 124 },
        { :name => "ao-ac-mam-otr-us", :fws => ['net-nat', "net-forward"], :ssid => "MAM-OTR-US", :ipsec => Resolv.getaddress("fanout-us.adviser.com"), :block => 125 }
      ].each do |net|
        wifi_ifs = []
        if WIFI_PSKS[net[:name]]
          wifi_vlans += wifi_ifs = [
            {:freq => 24, :master_if => wlan1 }
          ].map do |freq|
            ssid = "#{net[:ssid] || net[:name].sub(/^[a-zA-Z0-9]+-/,'')}-#{freq[:freq]}"
            simple_ssid = ssid.downcase.gsub(/[^0-9a-z]+/, '')
            wlan = region.interfaces.add_wlan(ap, "wl#{simple_ssid}",
                                              "mtu" => 1500,
                                              "vlan_id" => net[:block],
                                              "master_if" => freq[:master_if],
                                              "ssid" => ssid.upcase,
                                              "psk" => WIFI_PSKS[net[:name]])
          end
        end

        ac_router(region, net[:name], net[:block], [], mother)
#        wifi_ifs.each do |iface|
#          region.cables.add(iface, mother.interfaces.find_by_name("br#{net[:block]}"))
#        end
      end

      ether1 = region.interfaces.add_device(ap,  "ether1", "default_name" => "ether1")
      ether2 = region.interfaces.add_device(ap,  "ether2", "default_name" => "ether2")
      ap.configip = ap.id = Construqt::HostId.create do |my|
        my.interfaces << region.interfaces.add_bridge(ap, "bridge-local", "mtu" => 1500,
                                                      "interfaces" => [ether1,ether2]+wifi_vlans,
                                                      'address' => region.network.addresses.add_ip("169.254.70.9/24"))
      end
    end
  end

  def self.run(network)
    region = setup_region("always-connected", network)
    if ARGV.include?("ao-plantuml")
      require 'construqt/flavour/plantuml.rb'
      region.add_aspect(Construqt::Flavour::Plantuml.new)
    end
    region.dest_path(File.join("cfgs", region.name))
    mother = AlwaysConnected.mother(region)
    #AlwaysConnected.border_access(mother, "eth0")
    #AlwaysConnected.border_access(mother, "wlan0")

    AlwaysConnected.mam_otr(mother)
    #    AlwaysConnected.border_access(mother, "usb0")
    #    AlwaysConnected.border_access(mother, "usbnet0")

    #    AlwaysConnected.router(mother)
    #    AlwaysConnected.access_controller(mother)

    #    AlwaysConnected.access_pointer(mother, "de", "wlan1", "MAM-AL-DE",
    #                                   region.network.addresses.add_ip("169.254.69.65/24")
    #      .add_ip("fd:a9fe:49::65/64"))

    #    AlwaysConnected.encrypter_region(mother, "de", region.network.addresses.add_ip("169.254.69.97/24")
    #      .add_ip("fd:a9fe:49::97/64"))
    Construqt.produce(region)
  end

  def self.border_access(mother, ifname)
    region = mother.region
    address = region.network.addresses.add_ip("169.254.69.#{BORDER_ACCESS.length+33}/24")
      .add_ip("fd:a9fe:49::#{BORDER_ACCESS.length+33}/64")
    BORDER_ACCESS << region.hosts.add("ao-border-#{ifname}", "flavour" => "nixian",
                                      "dialect" => "ubuntu", "mother" => mother,
                                      "lxc_deploy" => Construqt::Hosts::Lxc.new.restart) do |host|
                                        region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                                                     :description=>"#{host.name} lo",
                                                                     "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
                                        host.configip = host.id ||= Construqt::HostId.create do |my|
                                          my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                                                                                                "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name("br666")),
                                                                                                'address' => address.add_route_from_tags("#INTERNET", "#ROUTER", "metric" => 100))
                                        end

                                        region.interfaces.add_device(mother, ifname, "mtu" => 1500)
                                        region.interfaces.add_device(host, "border", "mtu" => 1500,
                                                                     "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name(ifname)).type_phys,
                                                                     'address' => region.network.addresses.add_ip(Construqt::Addresses::DHCPV4))
                                      end
  end

  def self.mother(region)
    region.hosts.add("ao-mother", "flavour" => "nixian", "dialect" => "ubuntu") do |host|
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

      region.interfaces.add_bridge(host, "br0", "mtu" => 1500, "interfaces" => [
                                    region.interfaces.add_device(host, "eth0", "mtu" => 1500)
                                  ], 'address' => region.network.addresses.add_ip("169.254.70.1/24"))
    end
  end

  def self.router(mother)
    region = mother.region
    region.hosts.add("ao-router", "flavour" => "nixian", "dialect" => "ubuntu", "mother" => mother,
                     "lxc_deploy" => Construqt::Hosts::Lxc.new.restart) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                                                              "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name("br666")),
                                                              'address' => region.network.addresses.add_ip("169.254.69.8/24#ROUTER")
          .add_ip("fd:a9fe:49::8/64#ROUTER"))
      end
    end
  end

  def self.access_controller(mother)
    region = mother.region
    region.hosts.add("ao-access-ctl", "flavour" => "nixian", "dialect" => "ubuntu", "mother" => mother,
                     "lxc_deploy" => Construqt::Hosts::Lxc.new.restart) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                                                              "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name("br666")),
                                                              'address' => region.network.addresses.add_ip("169.254.70.4/24")
          .add_ip("fd:a9fe:49::4/64"))
      end
    end
  end

  def self.encrypter_region(mother, rname, address)
    region = mother.region
    region.hosts.add("ao-tunnel-#{rname}", "flavour" => "nixian", "dialect" => "ubuntu", "mother" => mother,
                     "lxc_deploy" => Construqt::Hosts::Lxc.new.restart) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                                                              "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name("br666")),
                                                              'address' => address)
      end
    end
  end

  def self.access_pointer(mother, rname, ifname, ssid, address)
    region = mother.region
    region.hosts.add("ao-ap-#{rname}-#{ifname}", "flavour" => "nixian", "dialect" => "ubuntu", "mother" => mother,
                     "lxc_deploy" => Construqt::Hosts::Lxc.new.restart) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                                                              "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name("br666")),
                                                              'address' => address)
      end

      region.interfaces.add_device(mother, ifname, "mtu" => 1500)
      region.interfaces.add_device(host, "wlan", "mtu" => 1500,
                                   "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name(ifname)).type_phys,
                                   'address' => region.network.addresses.add_ip("172.25.69.0/24"))
    end
  end

end
