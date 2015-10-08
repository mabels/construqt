begin
  require 'pry'
rescue e
  puts "no breaking bad"
end

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'../../../../'
[
  "#{CONSTRUQT_PATH}/ipaddress/lib",
  "#{CONSTRUQT_PATH}/construqt/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/plantuml/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ubuntu/lib"
].each{|path| $LOAD_PATH.unshift(path) }
require 'rubygems'
require 'construqt'
require 'construqt/flavour/plantuml.rb'

Construqt::Flavour::Plantuml.add_format('png')

network = Construqt::Networks.add('distille')
network.set_domain("distille.construqt.net")
network.set_contact("meno.abels.construqt.net")
network.set_dns_resolver(network.addresses.set_name("NAMESERVER").
    add_ip("8.8.8.8").
    add_ip("8.8.4.4"), [network.domain])

region = Construqt::Regions.add("scottland", network)


def distil_single_malt(region)
  region.hosts.add("single-malt", "flavour" => "ubuntu") do |host|
    region.interfaces.add_device(host, "lo", "mtu" => "9000",
       "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
    host.configip = host.id ||= Construqt::HostId.create do |my|
      my.interfaces << region.interfaces.add_device(host, "eth0",
                         "mtu" => 1500,
                         "address" => region.network.addresses.add_ip(Construqt::Addresses::DHCPV4))
    end
  end
end

distil_single_malt(region)

Construqt.produce(region)



