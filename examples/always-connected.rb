
module AlwaysConnected
  BORDER_ACCESS = {}
  ACCESS_ROUTER = {}

  def self.ac_router(region, name, block, fws, mother)
    ACCESS_ROUTER[name] = region.hosts.add(name, "flavour" => "nixian", "dialect" => "ubuntu", "mother" => mother,
                                           "lxc_deploy" => Construqt::Hosts::Lxc.new.aa_profile_unconfined.release("xenial")) do |host|
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
                                    'address' => region.network.addresses.add_ip("172.23.#{block}.1/24#NET-#{name}#AO-INTERNAL",
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
        { :name => "ao-ac-mam-otr",    :fws => ["net-forward"], :ssid => "MAM-OTR",    :block => 123 }, # homenet
        { :name => "ao-ac-mam-otr-de", :fws => ["net-forward"], :ssid => "MAM-OTR-DE", :ipsec => FANOUT_DE_ADVISER_COM, :block => 124 },
        { :name => "ao-ac-mam-otr-us", :fws => ["net-forward"], :ssid => "MAM-OTR-US", :ipsec => FANOUT_US_ADVISER_COM, :block => 125 }
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

        ac_router(region, net[:name], net[:block], net[:fws], mother)
#        wifi_ifs.each do |iface|
#          region.cables.add(iface, mother.interfaces.find_by_name("br#{net[:block]}"))
#        end
      end

      ether1 = region.interfaces.add_device(ap,  "ether1", "default_name" => "ether1")
      ether2 = region.interfaces.add_device(ap,  "ether2", "default_name" => "ether2")
      ap.configip = ap.id = Construqt::HostId.create do |my|
        my.interfaces << region.interfaces.add_bridge(ap, "bridge-local", "mtu" => 1500,
                                                      "interfaces" => [ether1,ether2]+wifi_vlans,
                                                      'address' => region.network.addresses.add_ip("169.254.70.9/24#AO-INTERNAL"))
      end
    end
  end

#  def self.create_templates(mother)
#    region = mother.region
#    region.hosts.add("ao-os-template", "flavour" => "nixian", "dialect" => "ubuntu",
#                     "mother" => mother,
#                     "lxc_deploy" => Construqt::Hosts::Lxc.new.template.upgrade) do |host|
#      region.interfaces.add_device(host, "lo", "mtu" => "9000",
#                                   :description=>"#{host.name} lo",
#                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
#      host.configip = host.id ||= Construqt::HostId.create do |my|
#        my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
#                              "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name("br666")),
#                              'address' => region.network.addresses.add_ip("169.254.69.248/24#ROUTER")
#          .add_ip("fd:a9fe:49::248/64#ROUTER"))
#      end
#    end
#    AlwaysConnected.router(mother, "ao-router-template", 249, Construqt::Hosts::Lxc.new.template.overlay("ao-os-template"))
#    AlwaysConnected.border_access(mother, "wlan-template", "lxc_deploy" => Construqt::Hosts::Lxc.new.stopped.clone("ao-os-template"))
#  end

  def self.run(network)
    region = setup_region("always-connected", network)
    tag_internet =  region.network.addresses.add_ip("0.0.0.0/0#INTERNET").add_ip("2000::/3#INTERNET")
    if ARGV.include?("ao-plantuml")
      require 'construqt/flavour/plantuml.rb'
      region.add_aspect(Construqt::Flavour::Plantuml.new)
    end
    region.dest_path(File.join("cfgs", region.name))
    mother = AlwaysConnected.mother(region)
    #AlwaysConnected.border_access(mother, "eth0")

    #AlwaysConnected.create_templates(mother)

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

    AlwaysConnected.border_access(mother, "wlx485d60a394cb", "ssid" => "espiritudelviento", "psk" => "0000000000")
    AlwaysConnected.border_access(mother, "wlxc4e9841f0822", "ssid" => "espiritudelviento", "psk" => "0000000000")
    AlwaysConnected.border_access(mother, "br0")
    AlwaysConnected.router(mother, "ao-router", 8, Construqt::Hosts::Lxc.new.restart.template("ao-template"))
    Construqt.produce(region)
  end

  def self.border_access(mother, ifname, options = {})
    region = mother.region
    address = region.network.addresses.add_ip("169.254.69.#{BORDER_ACCESS.length+33}/24#AO-INTERNAL")
      .add_ip("fd:a9fe:49::#{BORDER_ACCESS.length+33}/64")
    # "lxc_deploy" => Construqt::Hosts::Lxc.new.restart.template("ao-template")
    BORDER_ACCESS["ao-border-#{ifname}"] = region.hosts.add("ao-border-#{ifname}", "flavour" => "nixian",
                                      "dialect" => "ubuntu", "mother" => mother,
                                      "lxc_deploy" => Construqt::Hosts::Lxc.new.aa_profile_unconfined.release("xenial")) do |host|
                                        region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                                                     :description=>"#{host.name} lo",
                                                                     "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
                                        host.configip = host.id ||= Construqt::HostId.create do |my|
                                          my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                                                                                                "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name("br666")),
                                                                                                'address' => address.add_route_from_tags("#AO-INTERNAL", "#ROUTER", "metric" => 100))
                                        end

                                        mother_if = mother.interfaces.find_by_name!(ifname) || region.interfaces.add_device(mother, ifname, "mtu" => 1500)
                                        border_options = options.clone
                                        border_options["mtu"] = 1500
                                        border_options['firewalls'] = ['host-outbound', 'border-forward', 'border-masq', 'icmp-ping', 'block']
                                        border_options["address"] = region.network.addresses.add_ip(Construqt::Addresses::DHCPV4)
                                        border_options["plug_in"] = Construqt::Cables::Plugin.new.iface(mother_if)
                                        if border_options['ssid']
                                          border_options["plug_in"].type_phys
                                          region.interfaces.add_wlan(host, "border", border_options)
                                        else
                                          region.interfaces.add_device(host, "border", border_options)
                                        end
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
                                                              'address' => region.network.addresses.add_ip("169.254.69.1/24#AO-INTERNAL")
          .add_ip("fd:a9fe:49::1/64")
          .add_route_from_tags("#INTERNET", "#ROUTER", "metric" => 100))
      end

      region.interfaces.add_bridge(host, "br0", "mtu" => 1500, "interfaces" => [
                                    region.interfaces.add_device(host, "eth0", "mtu" => 1500)
                                  ], 'address' => region.network.addresses.add_ip("169.254.70.1/24#AO-INTERNAL"))
    end
  end

  def self.router(mother, name, ip, lxc_deploy)
    region = mother.region
    # "lxc_deploy" => lxc_deploy
    region.hosts.add(name, "flavour" => "nixian", "dialect" => "ubuntu", "mother" => mother) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                                                              "plug_in" => Construqt::Cables::Plugin.new.iface(mother.interfaces.find_by_name("br666")),
                                                              'address' => region.network.addresses.add_ip("169.254.69.#{ip}/24#ROUTER")
          .add_ip("fd:a9fe:49::#{ip}/64#ROUTER"))
      end
    end
  end

  def self.access_controller(mother)
    region = mother.region
    region.hosts.add("ao-access-ctl", "flavour" => "nixian", "dialect" => "ubuntu", "mother" => mother,
                     "lxc_deploy" => Construqt::Hosts::Lxc.new.restart.template("ao-template")) do |host|
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
    # "lxc_deploy" => Construqt::Hosts::Lxc.new.restart.template("ao-template")
    region.hosts.add("ao-tunnel-#{rname}", "flavour" => "nixian", "dialect" => "ubuntu", "mother" => mother) do |host|
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
    # "lxc_deploy" => Construqt::Hosts::Lxc.new.restart.template("ao-template")
    region.hosts.add("ao-ap-#{rname}-#{ifname}", "flavour" => "nixian", "dialect" => "ubuntu", "mother" => mother) do |host|
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
