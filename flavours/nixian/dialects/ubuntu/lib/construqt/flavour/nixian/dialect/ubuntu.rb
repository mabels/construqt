
require 'construqt/flavour/nixian.rb'

require_relative 'ubuntu/dns.rb'
require_relative 'ubuntu/ipsec/racoon.rb'
require_relative 'ubuntu/ipsec/strongswan.rb'
require_relative 'ubuntu/bgp.rb'
require_relative 'ubuntu/opvn.rb'
require_relative 'ubuntu/vrrp.rb'
require_relative 'ubuntu/firewall.rb'
require_relative 'ubuntu/container.rb'
require_relative 'ubuntu/lxc.rb'
require_relative 'ubuntu/docker.rb'
require_relative 'ubuntu/result.rb'

require_relative 'ubuntu/services/conntrack_d.rb'
require_relative 'ubuntu/services/dhcp_v4_relay.rb'
require_relative 'ubuntu/services/dhcp_v6_relay.rb'
require_relative 'ubuntu/services/null.rb'
require_relative 'ubuntu/services/radvd.rb'
require_relative 'ubuntu/services/route_service.rb'

require_relative 'ubuntu/bond.rb'
require_relative 'ubuntu/bridge.rb'
require_relative 'ubuntu/device.rb'
require_relative 'ubuntu/gre.rb'
require_relative 'ubuntu/host.rb'
require_relative 'ubuntu/ipsecvpn.rb'
require_relative 'ubuntu/template.rb'
require_relative 'ubuntu/vlan.rb'
require_relative 'ubuntu/wlan.rb'

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
            def produce(cfg)
              Dialect.new
            end
          end

          class Dialect
            def name
              'ubuntu'
            end

            #        def self.flavour_name
            #          'ubuntu'
            #        end

            #Construqt::Flavour::Nixian.add(self)


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
              host.result = Result.new(host)
              host
            end

            def create_interface(name, cfg)
              cfg['name'] = name
              clazz(cfg['clazz']).new(cfg)
            end

            def create_bgp(cfg)
              Bgp.new(cfg)
            end

            def create_ipsec(cfg)
              Ipsec::StrongSwan.new(cfg)
            end
          end
        end
      end
    end
  end
end
