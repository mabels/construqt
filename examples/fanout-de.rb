module FanoutDe
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
    }[:cx]
  end
  def self.run(region)
    fanout = self.cfg
    fanout_de = region.hosts.add("fanout-de", "flavour" => "nixian", "dialect" => "ubuntu") do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

      left_if = nil
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << left_if = region.interfaces.add_device(host, "eth0",
                                                                "mtu" => 1500,
                                                                'proxy_neigh' => Construqt::Tags.resolver_net("#SERVICE-TRANSIT-DE#SERVICE-NET-DE", Construqt::Addresses::IPV6),
                                                                'address' => region.network.addresses
          .add_ip(fanout[:ip])
          .add_service_ip("#{fanout[:ipe]}#FANOUT-DE")
          .add_route("0.0.0.0/0#INTERNET", fanout[:gw])
          .add_ip(fanout[:ip6])
          .add_route("2000::/3#INTERNET", fanout[:gw6]),
        "firewalls" => ["fix-mss", "host-outbound", "icmp-ping" , "http-srv", "ssh-srv", "ipsec-srv",
                        "service-ssh-hgw", "service-transit",
                        "service-sniproxy",
                        "service-woko", "service-jabber",
                        "service-nat", "service-smtp", "service-dns", "service-imap",
                        "vpn-server-net", "block"])
      end

      region.interfaces.add_ipsecvpn(host, "roadrunner",
                                     "mtu" => 1380,
                                     "users" => ipsec_users,
                                     "auth_method" => :internal,
                                     "left_interface" => left_if,
                                     "leftpsk" => IPSEC_LEFT_PSK,
                                     "leftcert" => region.network.cert_store.find_package("fanout-de"),
                                     "right_address" => region.network.addresses.add_ip("192.168.72.64/26#IPSECVPN-DE")
        .add_ip("#{fanout[:net6]}::cafe:0/112#IPSECVPN-DE"),
      "ipv6_proxy" => true)
      region.interfaces.add_bridge(host, "br12",
                                   "mtu" => 1500,
                                   "interfaces" => [],
                                   "address" => region.network.addresses.add_ip("169.254.12.1/24#FANOUT-DE-BACKEND#FANOUT-DE-BR12")
        .add_ip("#{fanout[:net6]}:169:254:12:1/123#FANOUT-DE-BACKEND"))
    end

    {'smtp-de' => nil,
     'bind-de' => nil,
     'imap-de' => nil,
     'ovpn' => lambda { |host|
       fanout = self.cfg
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
                                      "network" => region.network.addresses
                                        .add_ip("192.168.72.#{64*idx}/26#IPSECVPN-DE")
                                        .add_ip("#{fanout[:net6]}:192:168:72:#{64*idx}/122#IPSECVPN-DE"),
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
      'sniproxy' => nil
     }.each_with_index do |name_action, idx|
      name, action = name_action
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
            .add_ip("#{fanout[:net6]}:169:254:12:#{10+idx}/123#HOST-#{name}#SERVICE-NET-DE")
            .add_route("2000::/3", "#{fanout[:net6]}:169:254:12:1"))
        end
        action && action.call(host)
      end
    end

    fanout_de
  end
end
