
module Thieso
  def self.run(region)
    br0 = nil
    thieso = region.hosts.add("thieso", "flavour" => "nixian", "dialect" => "ubuntu",
                              "services" => [Construqt::Flavour::Nixian::Services::Vagrant::Service.new
      .box("ubuntu/xenial64").root_passwd("/.")
      .add_cfg('config.vm.network "public_network", bridge: "bridge0"')]) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

      host.configip = host.id ||= Construqt::HostId.create do |my|
        eth0 = region.interfaces.add_device(host, "enp0s8", "mtu" => 1500)
        host.configip = host.id ||= Construqt::HostId.create do |my|
          my.interfaces << br0 = region.interfaces.add_bridge(host, "br0",
            "mtu" => 1500,
            "interfaces" => [eth0],
            "address" => region.network.addresses
              .add_ip(Construqt::Addresses::DHCPV4)
              .add_ip("192.168.2.3/24")
              .add_route("0.0.0.0/0", "192.168.2.1"))
        end
      end
    end

    {
     'atv' => lambda { |host, iface|
       [
         { name: "tun1", proto: "udp" },
       ].each_with_index do |p, idx|
         region.interfaces.add_openvpn(host, p[:name],
                                       "cacert" => OPENVPN['ovpn']["cacert"],
                                       "hostcert" =>  OPENVPN['ovpn']["hostcert"],
                                       "hostkey" => OPENVPN['ovpn']["hostkey"],
                                       "dh" =>  OPENVPN['ovpn']["dhfile"],
                                       "listen" => iface,
                                       "network" => region.network.addresses
           .add_ip("192.168.72.#{64*idx}/26#IPSECVPN-DE"),
         :users => region.users,
         "proto" => p[:proto],
         "firewall"=>'notrack',
         "push_routes" => region.network.addresses
           .add_route("0.0.0.0/0"))
       end

     },
     'vm1' => nil,
     'vm2' => nil,
     'vm3' => nil,
    }.each_with_index do |name_action, idx|
       name, action = name_action
       puts "create:#{name}"
       region.hosts.add(name, "flavour" => "nixian", "dialect" => "ubuntu", "mother" => thieso,
                        "services" => [Construqt::Flavour::Nixian::Services::Invocation::Service.new(
                                        Construqt::Flavour::Nixian::Services::Lxc::Container.new
                                        .aa_profile_unconfined.restart.killstop)]) do |host|
                          region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                                       :description=>"#{host.name} lo",
                                                       "address" => region.network.addresses
                            .add_ip(Construqt::Addresses::LOOOPBACK))
                          iface = nil
                          host.configip = host.id ||= Construqt::HostId.create do |my|
                            my.interfaces << iface = region.interfaces.add_device(host, "eth0",
                              "plug_in" => Construqt::Cables::Plugin.new.iface(br0),
                              "mtu" => 1500,
                              'address' => region.network.addresses
                                .add_ip("192.168.2.#{2+idx}/24")
                                .add_route("0.0.0.0/0", "192.168.2.1"))
                          end

                          action && action.call(host, iface)
                        end
     end

     thieso
  end
end
