module FanoutUs
  def self.run(region)
    fanout_us = region.hosts.add("fanout-us", "flavour" => "nixian", "dialect" => "ubuntu") do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

      left_if = nil
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << left_if = region.interfaces.add_device(host, "eth0",
                                                                'proxy_neigh' => Construqt::Tags.resolver_net("#FANOUT-US-BACKEND", Construqt::Addresses::IPV6),
                                                                "mtu" => 1500,
                                                                'address' => region.network.addresses.add_ip("162.218.210.74/24#FANOUT-US")
          .add_route("0.0.0.0/0#INTERNET", "162.218.210.1")
          .add_ip("2602:ffea:1:7dd::eb38/44")
          .add_route("2000::/3#INTERNET", "2602:ffea:1::1"),
        "firewalls" => ["fix-mss", "host-us-outbound", "icmp-ping" , "http-srv",
                        "ssh-srv", "ipsec-srv", "service-us-transit", "vpn-server-net",
                        "service-us-nat", "service-us-smtp", "service-us-dns", "block"])
      end

      region.interfaces.add_ipsecvpn(host, "roadrunner",
                                     "mtu" => 1380,
                                     "users" => ipsec_users,
                                     "auth_method" => :internal,
                                     "left_interface" => left_if,
                                     "leftpsk" => IPSEC_LEFT_PSK,
                                     "leftcert" => region.network.cert_store.get_cert("fanout-us_adviser_com.crt"),
                                     "right_address" => region.network.addresses.add_ip("192.168.71.64/26#IPSECVPN-US")
        .add_ip("2602:ffea:1:7dd::cafe:0/112#IPSECVPN-US"),
      "ipv6_proxy" => true)

      region.interfaces.add_bridge(host, "br13",
                                   "mtu" => 1500,
                                   "interfaces" => [],
                                   "address" => region.network.addresses.add_ip("169.254.13.1/24#FANOUT-US-BACKEND#FANOUT-US-BR13")
        .add_ip("2602:ffea:1:7dd:169:254:13:1/123#FANOUT-US-BACKEND#FANOUT-US-BR13"))
    end

    ['smtp-us', 'bind-us'].each_with_index do |name, idx|
      region.hosts.add(name, "flavour" => "nixian", "dialect" => "ubuntu", "mother" => fanout_us,
                       "lxc_deploy" => Construqt::Hosts::Lxc.new.aa_profile_unconfined.restart.killstop) do |host|
        region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                     :description=>"#{host.name} lo",
                                     "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

        host.configip = host.id ||= Construqt::HostId.create do |my|
          my.interfaces << iface = region.interfaces.add_device(host, "eth0",
                                                                "plug_in" => Construqt::Cables::Plugin.new.iface(fanout_us.interfaces.find_by_name("br13")),
                                                                "mtu" => 1500,
                                                                'address' => region.network.addresses
            .add_ip("169.254.13.#{10+idx}/24#HOST-#{name}")
            .add_route("0.0.0.0/0", "169.254.13.1")
            .add_ip("2602:ffea:1:7dd:169:254:13:#{10+idx}/123#HOST-#{name}")
            .add_route("2000::/3", "2602:ffea:1:7dd:169:254:13:1"))
        end
      end
    end

    fanout_us
  end
end
