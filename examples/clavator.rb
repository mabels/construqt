
module Clavator
  def self.run(region)
    region.hosts.add("clavator", "flavour" => "nixian", "dialect" => "ubuntu") do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000", :description=>"#{host.name} lo",
        "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << region.interfaces.add_device(host, "eth0", "mtu" => 1500,
        'address' => region.network.addresses.add_ip("192.168.16.1/24",
          "dhcp" => Construqt::Dhcp.new.start("192.168.16.100").end("192.168.16.200").domain("clavator")))
      end
    end
  end
end
