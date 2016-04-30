begin
  require 'pry'
rescue LoadError
end

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'../../'
[
  "#{CONSTRUQT_PATH}/ipaddress/lib",
  "#{CONSTRUQT_PATH}/construqt/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/plantuml/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/gojs/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/dialects/ubuntu/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/mikrotik/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ciscian/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ciscian/dialects/hp/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/unknown/lib"
].each{|path| $LOAD_PATH.unshift(path) }
require 'rubygems'
require 'construqt'
require 'construqt/flavour/nixian'
require 'construqt/flavour/nixian/dialect/ubuntu'
require 'construqt/flavour/unknown'
require 'construqt/flavour/mikrotik'
require 'construqt/flavour/ciscian'
require 'construqt/flavour/ciscian/dialect/hp'

require_relative './firewall.rb'
if ARGV.include?("secure")
  require_relative './password.rb'
else
  require_relative './crashtestdummy.rb'
end

def setup_region(name, network)
  region = Construqt::Regions.add(name, network)
  nixian = Construqt::Flavour::Nixian::Factory.new
  nixian.add_dialect(Construqt::Flavour::Nixian::Dialect::Ubuntu::Factory.new)
  region.flavour_factory.add(nixian)
  region.flavour_factory.add(Construqt::Flavour::Unknown::Factory.new)
  region.flavour_factory.add(Construqt::Flavour::Mikrotik::Factory.new)
  ciscian = Construqt::Flavour::Ciscian::Factory.new
  ciscian.add_dialect(Construqt::Flavour::Ciscian::Dialect::Hp::Factory.new)
  region.flavour_factory.add(ciscian)
  if ARGV.include?("plantuml")
    require 'construqt/flavour/plantuml.rb'
    region.add_aspect(Construqt::Flavour::Plantuml.new)
  end
  region.network.ntp.add_server(region.network.addresses.add_ip("5.9.110.236").add_ip("178.23.124.2")).timezone("MET")
  region.services.add(Construqt::Services::Radvd.new("RADVD").adv_autonomous)


  region.users.add("menabe", "group" => "admin", "full_name" => "Meno Abels", "public_key" => <<KEY, "email" => "meno.abels@construqt.net")
ssh-dss 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 abels@nure
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHI6BvM+dh7vQW0qlhMJJ47Xh1sU1WFGKl4Z6dqkghf9 menabe@2guns.local
KEY
  region
end

network = Construqt::Networks.add('construqt')
network.set_domain("adviser.com")
network.set_contact("meno.abels.construqt.net")
network.set_dns_resolver(network.addresses.set_name("NAMESERVER").
                         add_ip("8.8.8.8").
                         add_ip("8.8.4.4"), [network.domain])
ipsec_certificate(network)

region = setup_region("winsen", network)

region.network.addresses.add_ip("192.168.0.1/24#KDE-WL");

firewall(region)


region.network.addresses.add_ip("2000::/3#DEFAULT")


# [
#   {:name => 'ad-de', :address => "169.254.12.10/24", :gw => "#FANOUT-DE-BR12", "mother" => fanout_de, "plug" => "br12" },
#   {:name => 'ad-us', :address => "169.254.13.10/24", :gw => "#FANOUT-US-BR13", "mother" => fanout_us, "plug" => "br13" }
# ].map{|i| OpenStruct.new(i) }.each do |cfg|
#   region.hosts.add(cfg.name, "flavour" => "ubuntu", "mother" => cfg['mother']) do |host|
#     region.interfaces.add_device(host, "lo", "mtu" => "1500",
#                                  :description=>"#{host.name} lo",
#                                  "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
#
#     host.configip = host.id ||= Construqt::HostId.create do |my|
#       my.interfaces << iface = region.interfaces.add_device(host, "eth0", "mtu" => 1500,
#                  'address' => region.network.addresses.add_ip("#{cfg.address}#HOST-#{cfg.name}")
#                                                        .add_route_from_tags("#INTERNET", cfg.gw))
#       region.cables.add(iface, region.interfaces.find(cfg['mother'], cfg['plug']))
#     end
#   end
# end

# armhf = region.hosts.add("armhf", "flavour" => "ubuntu", "mother" => fanout_de) do |host|
#   region.interfaces.add_device(host, "lo", "mtu" => "9000",
#                                :description=>"#{host.name} lo",
#                                "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
#   host.configip = host.id ||= Construqt::HostId.create do |my|
#     my.interfaces << iface = region.interfaces.add_device(host, "eth0", "mtu" => 1500,
#                    'address' => region.network.addresses.add_ip("169.254.12.17/24")
#                                 .add_route("0.0.0.0/0", "169.254.12.1"))
#     region.cables.add(iface, region.interfaces.find("fanout-de", "br12"))
#   end
# end


require_relative "./fanout-de.rb"
fanout_de = FanoutDe.run(region)

require_relative "./fanout-us.rb"
fanout_us = FanoutUs.run(region)

require_relative 'scable'
Scable.run(network, fanout_de)

require_relative "./fanout-connect.rb"
FanoutConnect.run(region, fanout_de, fanout_us)


require_relative "./hgw.rb"
Hgw.run(region, fanout_de)


require_relative "./mam-wl-rt.rb"
MamWl.run(region, {:de => fanout_de, :us => fanout_us})

require_relative "./scott.rb"
Scott.run(region)

require_relative "./ooble.rb"
Ooble.run(region)

Construqt.produce(region)

require_relative 'always-connected'
AlwaysConnected.run(network)



if ARGV.include?("de")
  require 'net/ssh'
  require 'net/scp'
  ["fanout-us", "fanout-de", "service-de-wl", "service-de-hgw"].each do |hname|
    host = region.hosts.find(hname)
    dest = host.id.first_ipv4.first_ipv4.to_s
    Construqt.logger.info "Copy deployer.sh to #{host.name}(#{dest})"
    Net::SCP.upload!(dest, 'root', "cfgs/#{host.name}/deployer.sh", "/root/deployer.sh")
    Net::SSH.start(dest.to_s, 'root' ) do |ssh|
      ssh.exec('bash /root/deployer.sh') do |ch, stream, data|
        puts data
      end
    end
  end
end
