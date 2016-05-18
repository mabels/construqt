module Scable
  def self.run(network, fanout_de)
    region = setup_region("scable", network)
    region.users.add("rashei", "group" => "admin", "full_name" => "Rasmus Heimbaecher", "public_key" => <<KEY, "email" => "rasmus.heimbaecher@construqt.net")
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAt6iYp/jAXPFfbIGjK8KfBvyyAGm9nPEow65V5kvLZVzn2TtyfIWZWdEv6fSxjuUWZZwxRSRbL+sExQ2yjlHV5Xb5a5NdxBryKeNaFAvyCS2lkDwpmvOhkUVMgOyip1wK/fd16SXEsPd6TE8AsngBPvsanU6Bfk6UKywXqosKZkaWPQxSFzy5+n8I5+wnpkuVMlUs/xDNf231tA0AHaBWc9z41xW/nScRqZT0f3fJK4H7U7X0FMjLMlkY0YfmeXcJWUSps5UNKbL2tW7DHBzlRArEos0sDr2zMERHfPTEkmEOednbhTQE3ALxCf6ylUR1eWhxzTZnK1gfbDn9Pxajsw== Rasmus Heimbaecher
KEY
    if ARGV.include?("ao-plantuml")
      require 'construqt/flavour/plantuml.rb'
      region.add_aspect(Construqt::Flavour::Plantuml.new)
    end
    region.dest_path(File.join("cfgs", region.name))
    region.set_dns_resolver(network.addresses.set_name("NAMESERVER").
                            add_ip("2001:4860:4860::8888").
                            add_ip("2001:4860:4860::8844"), [])
    [1,2].each do |id|
      region.hosts.add("scable-#{id}", "flavour" => "nixian", "dialect" => "ubuntu") do |host|
        region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

        host.configip = host.id ||= Construqt::HostId.create do |my|
          my.interfaces << left_if = region.interfaces.add_device(host, "enp7s0f1", "mtu" => 1500,
            'address' => region.network.addresses.add_ip("2a04:2f80:3:5cab:1e:#{id}::#{id}/112")
            .add_route("2000::/3", "2a04:2f80:3:5cab:1e:#{id}::0/112"),
          "firewalls" => ["host-outbound-simple", "service-transit-local", "icmp-ping" , "ipsec-srv", "ssh-srv", "block"])
        end

        Construqt::Ipsecs.connection("#{fanout_de.name}<=>#{host.name}",
                                       "password" => IPSEC_PASSWORDS.call(fanout_de.name, host.name),
                                       "transport_family" => Construqt::Addresses::IPV6,
                                       "mtu_v4" => 1360,
                                       "mtu_v6" => 1360,
                                       "left" => {
                                         "my" => region.network.addresses
                                                      .add_ip("#{FanoutDe.cfg[:net6]}:169:254:#{192+id}:1/126#SERVICE-TRANSIT-DE")
                                                      .add_ip("169.254.#{192+id}.1/30#SERVICE-IPSEC-DE#FANOUT-DE-SCABLE-#{id}")
                                                      .add_route_from_tags("#NET-#{fanout_de.name}", "#GW-#{fanout_de.name}"),
                                         "hosts" => [fanout_de],
                                         "remote" => region.interfaces.find(fanout_de, "eth0").address
                                       },
                                       "right" => {
                                         "my" => region.network.addresses
                                                     .add_ip("#{FanoutDe.cfg[:net6]}:169:254:#{192+id}:2/126#SERVICE-TRANSIT-DE")
                                                     .add_ip("169.254.#{192+id}.2/30#SERVICE-TRANSIT-DE")
                                                     .add_route_from_tags("#INTERNET", "#FANOUT-DE-SCABLE-#{id}"),
                                         "hosts" => [host],
                                         "remote" => region.interfaces.find(host, "enp7s0f1").address
                                       }
                                      )
      end

    end

    Construqt.produce(region)
  end
end
