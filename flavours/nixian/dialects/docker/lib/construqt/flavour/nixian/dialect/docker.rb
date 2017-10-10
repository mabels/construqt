
require 'construqt/flavour/nixian.rb'


require 'construqt/flavour/nixian/dialect/ubuntu'

require 'construqt/flavour/nixian/services'

require_relative 'host'
#
# require_relative 'arch/services/cloud_init_impl.rb'
# require_relative 'arch/services/vagrant_impl.rb'
# require_relative 'arch/services/remote_deploy_sh.rb'
# require_relative 'arch/services/packager_service.rb'
# require_relative 'arch/services/deployer_sh_service.rb'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Docker
          DIRECTORY = File.dirname(__FILE__)

          class Factory
            def name
              "docker"
            end

            def produce(parent, cfg)
              Dialect.new(parent, cfg)
            end
          end

          class Dialect
            attr_reader :services_factory, :update_channel, :image_version
            def initialize(factory, cfg)
              @factory = factory
              @cfg = cfg
              @services_factory = factory.services_factory.shadow()
            end

            def name
              'docker'
            end

            def add_host_services(srvs)
              @services_factory.merge(srvs, [
                Construqt::Packages::Builder.new,
                Construqt::Flavour::Nixian::Services::Result::Service.new,
                Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::Service.new,
                Construqt::Flavour::Nixian::Services::UpDowner::Service.new
                  .taste(Tastes::File::Factory.new)
              ])
            end

            def add_interface_services(srvs)
              srvs || []
            end

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
                "tunnel" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Tunnel,
                "vlan" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Vlan,
                "ipsecvpn" => Construqt::Flavour::Nixian::Dialect::Ubuntu::IpsecVpn,
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
              Host.new(cfg)
            end

            # def vagrant_factory(host, ohost)
            #   VagrantFile.new(host, ohost)
            # end

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
