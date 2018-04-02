module Bdog
  def self.cfg
    return {
      vx: {
        ipe: "78.47.4.51",
        ip: "78.47.4.51/29",
        gw: "78.47.4.49",
        ip6: "2a01:4f8:d15:1190:78:47:4:51/64",
        gw6: "2a01:4f8:d15:1190::1",
        net6: "2a01:4f8:d15:1190"
      },
      cx: {
        ipe: "78.46.188.238",
        ip: "172.31.1.100/24",
        gw: "172.31.1.1",
        ip6: "2a01:4f8:c17:186::2/64",
        gw6: "fe80::1",
        net6: "2a01:4f8:c17:186"
      },
      nx: {
        #ipe: "5.9.87.41",
        ipe: "@iscaac.adviser.com",
        ip: "5.9.87.41/27",
        gw: "5.9.87.33",
        ip6: "2a01:4f8:162:116a::2/64",
        gw6: "fe80::1",
        net6: "2a01:4f8:162:116a"
      },
    }[:nx]
  end

  def self.service_fw
    [
      "service-ssh-hgw", "service-transit",
      "service-sniproxy",
      "service-woko", "service-jabber",
      "service-nat", "service-smtp", "service-dns", "service-imap",
      "service-archlinux", "service-matrix",
      "service-ipsec"
    ]
  end

def self.run(region)
    bdog_cfg = self.cfg
    region.network.addresses.add_ip("172.17.0.0/16#SERVICE-NET-DE")
    region.network.addresses.add_ip("2a01:4f8:162:116a:172:17:0:2/120#SERVICE-NET-DE")

    bdog = region.hosts.add("bdog", "flavour" => "nixian", "dialect" => "ubuntu",
                            "services" => [
      Construqt::Flavour::Nixian::Services::Vagrant::Service.new
        .box("ubuntu/xenial64").root_passwd("/.")
        .add_cfg('config.vm.network "public_network", bridge: "bridge0"'),
      Construqt::Flavour::Nixian::Services::Docker::Service.new
        .docker_pkg("docker-ce")
        .hosts("[::]:2376").hosts("fd://")
        .tlscacert("/etc/letsencrypt/live/docker.clavator.net/chain.pem")
        .tlscert("/etc/letsencrypt/live/docker.clavator.net/cert.pem")
        .tlskey("/etc/letsencrypt/live/docker.clavator.net/privkey.pem")
        .tlsverify(true)
        .ip_masq(false)
        .storage_driver("zfs")
        .fixed_cidr_v6("2a01:4f8:162:116a:172:17:0:0/120")
        .ipv6(true)
    ]) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

      left_if = nil
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << left_if = region.interfaces.add_device(host, "eth0",
                                                                "mtu" => 1500,
                                                                'proxy_neigh' => Construqt::Tags.resolver_net("#SERVICE-TRANSIT-DE#SERVICE-NET-DE", Construqt::Addresses::IPV6),
                                                                'address' => region.network.addresses
          .add_ip(bdog_cfg[:ip])
          .add_service_ip("#{bdog_cfg[:ipe]}#BDOG")
          .add_route("0.0.0.0/0#INTERNET", bdog_cfg[:gw])
          .add_reject_route("#PRIVATE", { :metric => 2 })
          .add_ip(bdog_cfg[:ip6])
          .add_route("2000::/3#INTERNET", bdog_cfg[:gw6]),
        "firewalls" => ["fix-mss", "host-outbound", "icmp-ping" , "http-srv", "ssh-srv"]+
                       self.service_fw+["vpn-server-net", "block"])
      end

      region.interfaces.add_bridge(host, "br12",
                                   "mtu" => 1500,
                                   "interfaces" => [],
                                   "services" => [
                                     Construqt::Flavour::Nixian::Services::Docker::Network.new
                                   ],
                                   "address" => region.network.addresses.add_ip("169.254.12.1/24#BDOG-BACKEND#BDOG-BR12")
        .add_ip("#{bdog_cfg[:net6]}:169:254:12:1/120#BDOG-BACKEND"))
    end

    {'smtp-de' => nil,
     'bind-de' => nil,
     'imap-de' => nil,
     'ovpn' => lambda { |host, iface|
       bdog_cfg = self.cfg
       [
         { name: "tun1", proto: "udp" },
         { name: "tun2", proto: "udp6" },
         { name: "tun3", proto: "tcp" },
         { name: "tun4", proto: "tcp6" }
       ].each_with_index do |p, idx|
         region.interfaces.add_openvpn(host, p[:name],
                                       "cacert" => OPENVPN['ovpn']["cacert"],
                                       "hostcert" =>  OPENVPN['ovpn']["hostcert"],
                                       "hostkey" => OPENVPN['ovpn']["hostkey"],
                                       "dh" =>  OPENVPN['ovpn']["dhfile"],
                                       "listen" => iface,
                                       "network" => region.network.addresses
           .add_ip("192.168.72.#{64*idx}/26#IPSECVPN-DE")
           .add_ip("#{bdog_cfg[:net6]}:192:168:72:#{64*idx}/122#IPSECVPN-DE"),
         :users => region.users,
         "proto" => p[:proto],
         "firewall"=>'notrack',
         "push_routes" => region.network.addresses
           .add_route("0.0.0.0/0")
           .add_route("2000::/3"))
       end

     },
     'woko' => nil,
     'sni-test' => nil,
     'pam-gpg' => nil,
     'jabber' => nil,
     'posco' => nil,
     'trusty' => nil,
     'sniproxy' => nil,
     'iobroker' => nil
    }.each_with_index do |name_action, idx|
      name, action = name_action
      region.hosts.add(name, "flavour" => "nixian", "dialect" => "ubuntu", "mother" => bdog,
                       "services" => [
                         Construqt::Flavour::Nixian::Services::Invocation::Service.new(
                         Construqt::Flavour::Nixian::Services::Lxc::Container.new.aa_profile_unconfined.restart.killstop)
        ]) do |host|
        region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                     :description=>"#{host.name} lo",
                                     "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

        iface = nil
        host.configip = host.id ||= Construqt::HostId.create do |my|
          my.interfaces << iface = region.interfaces.add_device(host, "eth0",
                                                                "plug_in" => Construqt::Cables::Plugin.new.iface(bdog.interfaces.find_by_name("br12")),
                                                                "mtu" => 1500,
                                                                'address' => region.network.addresses
            .add_ip("169.254.12.#{10+idx}/24#HOST-#{name}#SERVICE-NET-DE")
            .add_route("0.0.0.0/0", "169.254.12.1")
            .add_ip("#{bdog_cfg[:net6]}:169:254:12:#{10+idx}/120#HOST-#{name}#SERVICE-NET-DE")
            .add_route("2000::/3", "#{bdog_cfg[:net6]}:169:254:12:1"))
        end

        action && action.call(host, iface)
      end
    end

    archlinux_clavator_com(region, bdog, bdog_cfg)
    matrix_adviser_com(region, bdog, bdog_cfg)
    iscaac_adviser_com(region, bdog, bdog_cfg)
    #
    bdog
  end

  def self.archlinux_clavator_com(region, bdog, bdog_cfg)
    name="archlinux"
    region.hosts.add(name, "flavour" => "nixian", "dialect" => "docker",
                     "mother" => bdog,
                     "services" => [
                     ]) do |host|
                       region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                                    :description=>"#{host.name} lo",
                                                    "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

                       iface = nil
                       host.configip = host.id ||= Construqt::HostId.create do |my|
                         my.interfaces << iface = region.interfaces.add_device(host, "eth0",
                                                                               "plug_in" => Construqt::Cables::Plugin.new.iface(bdog.interfaces.find_by_name("br12")),
                                                                               "mtu" => 1500,
                                                                               'address' => region.network.addresses
                           .add_ip("169.254.12.100/24#HOST-#{name}#SERVICE-NET-DE")
                           .add_route("0.0.0.0/0", "169.254.12.1")
                           .add_ip("#{bdog_cfg[:net6]}:169:254:12:64/120#HOST-#{name}#SERVICE-NET-DE")
                           .add_route("2000::/3", "#{bdog_cfg[:net6]}:169:254:12:1"))
                       end

                       #action && action.call(host, iface)
                     end
  end

  def self.iscaac_adviser_com(region, bdog, bdog_cfg)
    name = "iscaac"
    region.hosts.add(name, "flavour" => "nixian", "dialect" => "ubuntu", "mother" => bdog,
                     "services" => [
                       Construqt::Flavour::Nixian::Services::Invocation::Service.new(
                       Construqt::Flavour::Nixian::Services::Lxc::Container.new.aa_profile_unconfined.restart.killstop)]) do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

      iface = nil
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << iface = region.interfaces.add_bridge(host, 'brvx',
          "interfaces" => [
          region.interfaces.add_device(host, "eth0",
            "plug_in" => Construqt::Cables::Plugin.new.iface(bdog.interfaces.find_by_name("br12")),
            "mtu" => 1500)],
          "firewalls" => ["ipsec-nat"],
          'address' => region.network.addresses
          .add_ip("169.254.12.99/24#HOST-#{name}#SERVICE-NET-DE")
          .add_service_ip("#{bdog_cfg[:ipe]}#ISCAAC")
          .add_route("0.0.0.0/0", "169.254.12.1")
          .add_ip("#{bdog_cfg[:net6]}:169:254:12:99/120#HOST-#{name}#SERVICE-NET-DE")
          .add_route("2000::/3", "#{bdog_cfg[:net6]}:169:254:12:1"))
      end

     region.interfaces.add_ipsecvpn(host, "roadrunner",
        "mtu" => 1380,
        "users" => ipsec_users,
        "auth_method" => :internal,
        "left_interface" => iface,
        "leftpsk" => IPSEC_LEFT_PSK,
        "leftcert" => region.network.cert_store.find_package("iscaac"),
        "right_address" => region.network.addresses
          .add_ip("192.168.72.64/26#IPSECVPN-DE")
          .add_ip("#{bdog_cfg[:net6]}::cafe:0/112#IPSECVPN-DE"),
        "ipv6_proxy" => true)
    end
  end

  def self.matrix_adviser_com(region, bdog, bdog_cfg)
    name="matrix"
    region.hosts.add(name, "flavour" => "nixian", "dialect" => "docker",
                     "mother" => bdog,
                     "services" => []) do |host|
                       region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                                    :description=>"#{host.name} lo",
                                                    "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

                       iface = nil
                       host.configip = host.id ||= Construqt::HostId.create do |my|
                         my.interfaces << iface = region.interfaces.add_device(host, "eth0",
                                                                               "plug_in" => Construqt::Cables::Plugin.new.iface(bdog.interfaces.find_by_name("br12")),
                                                                               "mtu" => 1500,
                                                                               'address' => region.network.addresses
                           .add_ip("169.254.12.90/24#HOST-#{name}#SERVICE-NET-DE")
                           .add_route("0.0.0.0/0", "169.254.12.1")
                           .add_ip("#{bdog_cfg[:net6]}:169:254:12:90/120#HOST-#{name}#SERVICE-NET-DE")
                           .add_route("2000::/3", "#{bdog_cfg[:net6]}:169:254:12:1"))
                       end

                       #action && action.call(host, iface)
                     end
  end
end
