
module Ooble

  def self.run(region)
    # ooble-mother
    #   - ooble-border-br0
    #   - ooble-ipsec-gw
    ooble_mother_br666 = nil
    ooble_mother_br0 = nil
    ooble_mother = region.hosts.add("ooble-mother", "flavour" => "nixian", "dialect" => "ubuntu") do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << ooble_mother_br0 = region.interfaces.add_bridge(host, "br0", "mtu" => 1500,
                                                      "interfaces" => [
                                                        region.interfaces.add_device(host, "eth0", "mtu" => 1500)
                                                      ],
                                                      "address" => region.network.addresses.add_ip("169.254.71.1/24"))
      end
      ooble_mother_br666 = region.interfaces.add_bridge(host, "br666", "mtu" => 1500,
                  "interfaces" => [],
                  'address' => region.network.addresses.add_ip("169.254.72.1/24#AO-INTERNAL")
                                                       .add_ip("fd:a9fe:4c::1/64"))
    end

    # "lxc_deploy" => Construqt::Flavour::Nixian::Services::Lxc.new.restart.template("ao-template")
    ooble_border_br0 = region.hosts.add("ooble-border-br0", "flavour" => "nixian",
      "dialect" => "ubuntu", "mother" => ooble_mother,
      "services" => [Construqt::Flavour::Nixian::Services::Lxc.new.aa_profile_unconfined
                      .release("wily").template("ao-template")]) do |host|
        region.interfaces.add_device(host, "lo", "mtu" => "9000",
                     :description=>"#{host.name} lo",
                     "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
        host.configip = host.id ||= Construqt::HostId.create do |my|
          my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                    "plug_in" => Construqt::Cables::Plugin.new.iface(ooble_mother_br666),
                    'address' => region.network.addresses.add_ip("169.254.72.9/24#AO-INTERNAL")
                                                         .add_ip("fd:a9fe:4c::9/64"))
        end

        mother_if = ooble_mother_br0
        border_options = {}
        border_options["mtu"] = 1500
        #border_options['firewalls'] = ['border-forward', 'border-masq', 'icmp-ping', 'block']
        border_options["address"] = region.network.addresses.add_ip(Construqt::Addresses::DHCPV4)
        border_options["plug_in"] = Construqt::Cables::Plugin.new.iface(mother_if)
        region.interfaces.add_device(host, "border", border_options)
    end

    ooble_ipsec_gw = region.hosts.add("ooble-ipsec-gw", "flavour" => "nixian", "dialect" => "ubuntu",
        "mother" => ooble_mother,
        "services" => [Construqt::Flavour::Nixian::Services::Lxc.new.aa_profile_unconfined
                        .release("wily").template("ao-template")]) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      region.network.addresses.add_ip("192.168.178.1/24#KDE-HGW");
      host.configip = host.id ||= Construqt::HostId.create do |my|
          my.interfaces << iface = region.interfaces.add_device(host, "br666", "mtu" => 1500,
                          "plug_in" => Construqt::Cables::Plugin.new.iface(ooble_mother_br666),
                          'address' => region.network.addresses.add_ip("169.254.72.10/24#AO-INTERNAL")
                                       .add_route("0.0.0.0/0", "169.254.72.9"))
      end
    end
  end

end
