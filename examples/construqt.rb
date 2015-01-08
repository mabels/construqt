
require 'net/ssh'
require 'net/scp'

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'../../'
["#{CONSTRUQT_PATH}/ipaddress/lib","#{CONSTRUQT_PATH}/construqt/lib"].each{|path| $LOAD_PATH.unshift(path) }
require 'rubygems'
require 'construqt'

Construqt::Flavour::del_aspect("plantuml") unless ARGV.include?("plantuml")

network = Construqt::Networks.add('construqt')
network.set_domain("construqt.net")
network.set_contact("meno.abels.construqt.net")
network.set_dns_resolver(network.addresses.set_name("NAMESERVER").
                         add_ip("8.8.8.8").
                         add_ip("8.8.4.4"), [network.domain])
region = Construqt::Regions.add("winsen", network)

region.services.add(Construqt::Services::Radvd.new("RADVD").adv_autonomous)


region.users.add("menabe", "full_name" => "Meno Abels", "public_key" => <<KEY, "email" => "meno.abels@construqt.net")
ssh-dss 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 abels@nure
KEY


fw_outbound = Construqt::Firewalls.add("fw-outbound") do |fw|
  fw.forward do |forward|
    forward.add.action(Construqt::Firewalls::Actions::ACCEPT).interface.connection.from_my_net.to_net("DEFAULT").from_is(:inbound)
    forward.add.action(Construqt::Firewalls::Actions::DROP).log("FORWARD")
  end
end

region.network.addresses.add_ip("2000::/3#DEFAULT")

region.hosts.add("aiccu", "flavour" => "ubuntu") do |aiccu|
  region.interfaces.add_device(aiccu, "lo", "mtu" => "1500",
                               :description=>"#{aiccu.name} lo",
                               "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))


  aiccu.configip = aiccu.id ||= Construqt::HostId.create do |my|
    my.interfaces << region.interfaces.add_device(aiccu, "eth0", "mtu" => 1500,
                                                  "firewalls" => [ fw_outbound ],
                                                  'address' => region.network.addresses
                                                      .add_ip("192.168.176.9/24").add_route("0.0.0.0/0", "192.168.176.4")
                                                      .add_ip("2001:6f8:900:82bf::9/64"))
  end
end

Construqt.produce(region)
