
require 'construqt/flavour/nixian.rb'

require 'construqt/flavours/nixian/tastes/entities.rb'
require 'construqt/flavours/nixian/tastes/systemd.rb'
require 'construqt/flavours/nixian/tastes/flat.rb'
require 'construqt/flavours/nixian/tastes/debian.rb'

require_relative 'ubuntu/dns.rb'
require_relative 'ubuntu/ipsec/racoon.rb'
require_relative 'ubuntu/ipsec/strongswan.rb'
require_relative 'ubuntu/bgp.rb'
require_relative 'ubuntu/opvn.rb'
require_relative 'ubuntu/vrrp.rb'
require_relative 'ubuntu/firewall.rb'
require_relative 'ubuntu/container.rb'
require_relative 'ubuntu/result/up_downer.rb'
require_relative 'ubuntu/result.rb'

# require_relative 'ubuntu/services/conntrack_d.rb'
# require_relative 'ubuntu/services/dns_masq.rb'
# require_relative 'ubuntu/services/dhcp_client.rb'
# require_relative 'ubuntu/services/dhcp_v4_relay.rb'
# require_relative 'ubuntu/services/dhcp_v6_relay.rb'
# require_relative 'ubuntu/services/null.rb'
# require_relative 'ubuntu/services/radvd.rb'
# require_relative 'ubuntu/services/route_service.rb'
# require_relative 'ubuntu/services/vagrant.rb'
# require_relative 'ubuntu/services/docker.rb'
require_relative 'ubuntu/services/vagrant_impl.rb'

require_relative 'ubuntu/bond.rb'
require_relative 'ubuntu/bridge.rb'
require_relative 'ubuntu/device.rb'
require_relative 'ubuntu/gre.rb'
require_relative 'ubuntu/host.rb'
require_relative 'ubuntu/ipsecvpn.rb'
require_relative 'ubuntu/template.rb'
require_relative 'ubuntu/vlan.rb'
require_relative 'ubuntu/wlan.rb'
require_relative 'ubuntu/systemd.rb'
require_relative 'ubuntu/tunnel.rb'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          DIRECTORY = File.dirname(__FILE__)

          class Factory
            def name
              "ubuntu"
            end
            def produce(parent, cfg)
              Dialect.new(parent, cfg)
            end
          end

          class Dialect
            attr_reader :services
            def initialize(factory, cfg)
              @factory = factory
              @cfg = cfg
              @services = factory.services.shadow()
            end

            def name
              'ubuntu'
            end

            def add_host_services(srvs)
              srvs ||= []
              srvs += [Construqt::Flavour::Nixian::Services::Lxc.new(),
                      Construqt::Flavour::Nixian::Services::Docker.new(),
                      Construqt::Flavour::Nixian::Services::Vagrant.new()]
              throw "unknown services" unless @services.are_registered_by_instance?(srvs)
              srvs
            end

            def add_interface_services(srvs)
              srvs ||= []
              srvs += [
                Construqt::Flavour::Nixian::Services::DnsMasq.new(),
                Construqt::Flavour::Nixian::Services::DhcpClient.new()
              ]
              throw "unknown services" unless @services.are_registered_by_instance?(srvs)
              srvs
            end

            def ipsec
              Ipsec::StrongSwan
            end

            def bgp
              Bgp
            end

            def clazzes
              {
                "opvn" => Opvn,
                "gre" => Gre,
                "host" => Host,
                "device"=> Device,
                "vrrp" => Vrrp,
                "bridge" => Bridge,
                "bond" => Bond,
                "wlan" => Wlan,
                "vlan" => Vlan,
                "ipsecvpn" => IpsecVpn,
                "tunnel" => Tunnel,
                #"result" => Result,
                #"ipsec" => Ipsec,
                #"bgp" => Bgp,
                "template" => Template
              }
            end

            def clazz(name)
              ret = self.clazzes[name]
              throw "class not found #{name}" unless ret
              ret
            end

            def create_host(name, cfg)
              cfg['name'] = name
              cfg['result'] = nil
              host = Host.new(cfg)
              up_downer = Result::UpDowner.new(self)
                 .taste(Tastes::Systemd::Factory.new)
                 .taste(Tastes::Debian::Factory.new)
                 .taste(Tastes::Flat::Factory.new)
              host.result = Result.new(host, up_downer)
              @services.add(Services::VagrantImpl.new)
              # host.flavour.services.each do |srv|
              #   up_downer.request_tastes_from(srv)
              # end
              host
            end

            def create_interface(name, cfg)
              cfg['name'] = name
              clazz(cfg['clazz']).new(cfg)
            end

            def create_bgp(cfg)
              Bgp.new(cfg)
            end

            # def vagrant_factory(host, ohost)
            #   Services::VagrantFile.new(host, ohost)
            # end

            def create_ipsec(cfg)
              Ipsec::StrongSwan.new(cfg)
            end
          end
        end
      end
    end
  end
end
