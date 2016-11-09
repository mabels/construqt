
require 'construqt/flavour/nixian.rb'


require 'construqt/flavour/nixian/dialect/ubuntu.rb'

require_relative 'coreos/result.rb'
require_relative 'coreos/vagrant_file.rb'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module CoreOs
          DIRECTORY = File.dirname(__FILE__)

          class Factory
            def name
              "coreos"
            end
            def produce(cfg)
              Dialect.new
            end
          end

          class Dialect
            def name
              'coreos'
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
                "opvn" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Opvn,
                "gre" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Gre,
                "host" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Host,
                "device"=> Construqt::Flavour::Nixian::Dialect::Ubuntu::Device,
                "vrrp" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Vrrp,
                "bridge" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Bridge,
                "bond" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Bond,
                "wlan" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Wlan,
                "vlan" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Vlan,
                "ipsecvpn" => Construqt::Flavour::Nixian::Dialect::Ubuntu::IpsecVpn,
                #"result" => Result,
                #"ipsec" => Ipsec,
                #"bgp" => Bgp,
                "template" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Template
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
              host = Construqt::Flavour::Nixian::Dialect::Ubuntu::Host.new(cfg)
              host.result = CoreOs::Result.new(host)
              #binding.pry
              host
            end

            def vagrant_factory(host, ohost)
              VagrantFile.new(host, ohost)
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
