module Scable
  def self.run(network)
    region = setup_region("scable", network)
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
          my.interfaces << left_if = region.interfaces.add_device(host, "eth0", "mtu" => 1500,
            'address' => region.network.addresses.add_ip("2a04:2f80:4:5cab:1e:#{id}::#{id}/112")
            .add_route("2000::/3", "2a04:2f80:4:5cab:1e:#{id}::0/112"),
          "firewalls" => ["host-outbound", "icmp-ping" , "ssh-srv", "block"])
        end
      end
    end
    Construqt.produce(region)
  end
end
