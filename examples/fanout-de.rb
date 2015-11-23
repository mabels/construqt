module FanoutDe
  def self.run(region)
    fanout_de = region.hosts.add("fanout-de", "flavour" => "nixian", "dialect" => "ubuntu") do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

      left_if = nil
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << left_if = region.interfaces.add_device(host, "eth0",
                                                                "mtu" => 1500,
                                                                'proxy_neigh' => Construqt::Tags.resolver_net("#SERVICE-TRANSIT-DE#SERVICE-NET-DE", Construqt::Addresses::IPV6),
                                                                'address' => region.network.addresses.add_ip("78.47.4.51/29#FANOUT-DE")
          .add_route("0.0.0.0/0#INTERNET", "78.47.4.49")
          .add_ip("2a01:4f8:d15:1190:78:47:4:51/64")
          .add_route("2000::/3#INTERNET", "2a01:4f8:d15:1190::1"),
        "firewalls" => ["fix-mss", "host-outbound", "icmp-ping" , "ssh-srv", "ipsec-srv", "service-ssh-hgw",
                        "service-transit",
                        "service-nat", "service-smtp", "service-dns", "service-imap", "vpn-server-net", "block"])
      end

      region.interfaces.add_ipsecvpn(host, "roadrunner",
                                     "mtu" => 1380,
                                     "users" => ipsec_users,
                                     "auth_method" => :internal,
                                     "left_interface" => left_if,
                                     "leftpsk" => IPSEC_LEFT_PSK,
                                     "leftcert" => region.network.cert_store.get_cert("fanout-de_adviser_com.crt"),
                                     "right_address" => region.network.addresses.add_ip("192.168.72.64/26#IPSECVPN-DE")
        .add_ip("2a01:4f8:d15:1190::cafe:0/112#IPSECVPN-DE"),
      "ipv6_proxy" => true)
      region.interfaces.add_bridge(host, "br12",
                                   "mtu" => 1500,
                                   "interfaces" => [],
                                   "address" => region.network.addresses.add_ip("169.254.12.1/24#FANOUT-DE-BACKEND#FANOUT-DE-BR12")
        .add_ip("2a01:4f8:d15:1190:169:254:12:1/123#FANOUT-DE-BACKEND"))
    end

    ['smtp-de', 'bind-de', 'imap-de'].each_with_index do |name, idx|
      region.hosts.add(name, "flavour" => "nixian", "dialect" => "ubuntu", "mother" => fanout_de,
                       "lxc_deploy" => Construqt::Hosts::Lxc.new.aa_profile_unconfined.restart.killstop) do |host|
        region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                     :description=>"#{host.name} lo",
                                     "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

        host.configip = host.id ||= Construqt::HostId.create do |my|
          my.interfaces << iface = region.interfaces.add_device(host, "eth0",
                                                                "plug_in" => Construqt::Cables::Plugin.new.iface(fanout_de.interfaces.find_by_name("br12")),
                                                                "mtu" => 1500,
                                                                'address' => region.network.addresses
            .add_ip("169.254.12.#{10+idx}/24#HOST-#{name}#SERVICE-NET-DE")
            .add_route("0.0.0.0/0", "169.254.12.1")
            .add_ip("2a01:4f8:d15:1190:169:254:12:#{10+idx}/123#HOST-#{name}#SERVICE-NET-DE")
            .add_route("2000::/3", "2a01:4f8:d15:1190:169:254:12:1"))
        end
      end
    end
    fanout_de
  end
end
