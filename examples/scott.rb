module Scott
  def self.run(region)
    scott = region.hosts.add("scott", "flavour" => "nixian", "dialect" => "arch",
                             "services" => [Construqt::Flavour::Nixian::Services::Vagrant::Service.new
                                          .box("ubuntu/xenial64").root_passwd("/.")
                                          .add_cfg('config.vm.network "public_network", bridge: "bridge0"')]) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      eth0 = region.interfaces.add_device(host, "enp0s25", "mtu" => 1500)
      region.cables.add(eth0, region.interfaces.find("sw-hp03", "ge4"))

      [24,66,67,68,202].each do |vlan|
        region.interfaces.add_bridge(host, "br#{vlan}", "mtu" => 1500,
                                     "interfaces" => [
                                       region.interfaces.add_vlan(host, "#{eth0.name}.#{vlan}",
                                                                  "vlan_id" => vlan,
                                                                  "mtu" => 1500,
                                                                  "interface" => eth0)])
      end
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << hostif = region.interfaces.find(host, 'br202')
        hostif.address.add_ip("192.168.202.4/24").add_route("0.0.0.0/0", "192.168.202.1")
      end
    end

    region.hosts.add("aiccu", "flavour" => "nixian", "dialect" => "ubuntu",
                     "mother" => scott, "services" => [Construqt::Flavour::Nixian::Services::Lxc::Service.new]) do |aiccu|
      region.interfaces.add_device(aiccu, "lo", "mtu" => "1500",
                                   :description=>"#{aiccu.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

      region.interfaces.add_device(aiccu, "sixxs", "mtu" => "1280",
                                   "dynamic" => true,
                                   "firewalls" => [ "fw-sixxs" ],
                                   "address" => region.network.addresses.add_ip("2001:6f8:900:2bf::2/64"))

      aiccu.configip = aiccu.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_device(aiccu, "eth0", "mtu" => 1500,
                                                              "firewalls" => [ "fw-outbound" ],
                                                              'address' => region.network.addresses.add_ip("192.168.67.2/24")
          .add_route("0.0.0.0/0", "192.168.67.1")
          .add_ip("2001:6f8:900:82bf::2/64"))
        region.cables.add(iface, region.interfaces.find("scott", "br67"))
      end

      fbsd = region.hosts.add("fbsd", "flavour" => "nixian", "dialect" => "ubuntu",
                              "mother" => scott, "services" => [Construqt::Flavour::Nixian::Services::Lxc::Service.new]) do |host|
        region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                     :description=>"#{host.name} lo",
                                     "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
        host.configip = host.id ||= Construqt::HostId.create do |my|
          my.interfaces << my = region.interfaces.add_device(host, "vtnet0", "mtu" => 1500,
                                                             'address' => region.network.addresses.add_ip("192.168.176.19/24")
            .add_route_from_tags("#INTERNET", "192.168.176.4"))
          #region.cables.add(my, region.interfaces.find("scott", "enp0s25"))
        end
      end
    end
  end
end
