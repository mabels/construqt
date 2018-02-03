begin
  require 'pry'
rescue LoadError
end

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'../../'
[
  "#{CONSTRUQT_PATH}/ipaddress/ruby/lib",
  "#{CONSTRUQT_PATH}/construqt/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/plantuml/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/vis/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/gojs/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/tastes/entities/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/dialects/arch/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/dialects/coreos/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/dialects/ubuntu/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/dialects/debian/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/dialects/docker/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/services/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/tastes/systemd/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/tastes/flat/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/tastes/debian/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/tastes/file/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/mikrotik/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ciscian/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ciscian/dialects/dlink/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ciscian/dialects/dell/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ciscian/dialects/hp/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/unknown/lib"
].each{|path| $LOAD_PATH.unshift(path) }
require 'rubygems'
require 'construqt'
require 'construqt/flavour/nixian'
require 'construqt/flavour/nixian/dialect/ubuntu'
require 'construqt/flavour/nixian/dialect/debian'
require 'construqt/flavour/nixian/dialect/coreos'
require 'construqt/flavour/nixian/dialect/arch'
require 'construqt/flavour/nixian/dialect/docker'
require 'construqt/flavour/unknown'
require 'construqt/flavour/mikrotik'
require 'construqt/flavour/ciscian'
require 'construqt/flavour/ciscian/dialect/hp'
require 'construqt/flavour/ciscian/dialect/dell'
require 'construqt/flavour/ciscian/dialect/dlink'

require_relative './firewall.rb'
if ARGV.include?("secure")
  require_relative './password.rb'
else
  require_relative './crashtestdummy.rb'
end
require_relative "./postfix.rb"
require_relative "./aiccu.rb"

def setup_region(name, network)
  region = Construqt::Regions.add(name, network)
  nixian = Construqt::Flavour::Nixian::Factory.new
  nixian.services_factory.add(Postfix::Factory.new)
  nixian.services_factory.add(Aiccu::Factory.new)
  nixian.add_dialect(Construqt::Flavour::Nixian::Dialect::CoreOs::Factory.new)
  nixian.add_dialect(Construqt::Flavour::Nixian::Dialect::Ubuntu::Factory.new)
  nixian.add_dialect(Construqt::Flavour::Nixian::Dialect::Debian::Factory.new)
  nixian.add_dialect(Construqt::Flavour::Nixian::Dialect::Arch::Factory.new)
  nixian.add_dialect(Construqt::Flavour::Nixian::Dialect::Docker::Factory.new)
  region.flavour_factory.add(nixian)
  region.flavour_factory.add(Construqt::Flavour::Unknown::Factory.new)
  region.flavour_factory.add(Construqt::Flavour::Mikrotik::Factory.new)
  ciscian = Construqt::Flavour::Ciscian::Factory.new
  ciscian.add_dialect(Construqt::Flavour::Ciscian::Dialect::Dell::Factory.new)
  ciscian.add_dialect(Construqt::Flavour::Ciscian::Dialect::Dlink::Factory.new)
  ciscian.add_dialect(Construqt::Flavour::Ciscian::Dialect::Hp::Factory.new)
  region.flavour_factory.add(ciscian)
  if ARGV.include?("plantuml")
    require 'construqt/flavour/plantuml.rb'
    region.add_aspect(Construqt::Flavour::Plantuml.new)
  end
  if ARGV.include?("vis")
    require 'construqt/flavour/vis.rb'
    region.add_aspect(Construqt::Flavour::Vis.new)
  end

  region.network.ntp.add_server(region.network.addresses.add_ip("5.9.110.236").add_ip("178.23.124.2")).timezone("MET")
  #region.services.add(Construqt::Services::Radvd.new("RADVD").adv_autonomous)

  region.users.add("menabe", "group" => "admin", "full_name" => "Meno Abels", "public_key" => <<KEY, "email" => "meno.abels@construqt.net")
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIQpC2scaVXEaNuwtq4n6Vtht2WHYxtDFKe44JNFEsZGyQjyL9c2qkmQQGCF+2g3HrIPDTCCCWQ3GUiXGAlQ0/rf6sLqcm4YMXt+hgHU5VeciUIDEySCKdCPC419wFPBw6oKdcN1pLoIdWoF4LRDcjcrKKAlkdNJ/oLnl716piLdchABO9NXGxBpkLsJGK8qw390O1ZqZMe9wEAL9l/A1/49v8LfzELp0/fhSmiXphTVI/zNVIp/QIytXzRg74xcYpBjHk1TQZHuz/HYYsWwccnu7vYaTDX0CCoAyEt599f9u+JQ4oW0qyLO0ie7YcmR6nGEW4DMsPcfdqqo2VyYy4ix3U5RI2JcObfP0snYwPtAdVeeeReXi3c/E7bGLeCcwdFeFBfHSA9PDGxWVlxh/oCJaE7kP7eBhXNjN05FodVdNczKI5T9etfQ9VHILFrvpEREg1+OTiI58RmwjxS5ThloqXvr/nZzhIwTsED0KNW8wE4pjyotDJ8jaW2d7oVIMdWqE2M9Z1sLqDDdhHdVMFxk6Hl2XfqeqO2Jnst7qzbHAN/S3hvSwysixWJEcLDVG+cg1KRwz4qafCU5oHSp8aNNOk4RZozboFjac17nOmfPfnjC/LLayjSkEBZ+eFi+njZRLDN92k3PvHYFEB3USbHYzICsuDcf+L4cslX03g7w== openpgp:0x5F1BE34D
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

region.network.addresses.add_ip("10.0.0.0/8#PRIVATE")
region.network.addresses.add_ip("169.254.0.0/16#PRIVATE")
region.network.addresses.add_ip("172.16.0.0/12#PRIVATE")
region.network.addresses.add_ip("192.168.0.0/16#PRIVATE")
region.network.addresses.add_ip("fd00::/8#PRIVATE")


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


#require_relative "./fanout-de.rb"
#fanout_de = FanoutDe.run(region)

require_relative "./bdog.rb"
bdog = Bdog.run(region)


#require_relative "./fanout-us.rb"
#fanout_us = FanoutUs.run(region)

#require_relative 'scable'
#Scable.run(network, fanout_de)

#require_relative "./fanout-connect.rb"
#FanoutConnect.run(region, fanout_de, fanout_us)


require_relative "./hgw.rb"
Hgw.run(region, region.hosts.find("iscaac"), Bdog.cfg)


require_relative "./mam-wl-rt.rb"
MamWl.run(region, {:de => region.hosts.find("iscaac") }, Bdog.cfg) # :us => fanout_us})

require_relative "./scott.rb"
Scott.run(region)

require_relative "./thieso.rb"
Thieso.run(region)

require_relative "./wl-ccu.rb"
WlCcu.run(region, region.hosts.find("iscaac"))

require_relative "./ooble.rb"
Ooble.run(region)

Postfix.run(region)

require_relative "./clavator.rb"
Clavator.run(region)

Construqt.produce(region)

#require_relative 'always-connected'
#AlwaysConnected.run(network)



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
