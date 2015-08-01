
require_relative 'flavour_ubuntu_dns.rb'
require_relative 'flavour_ubuntu_ipsec.rb'
require_relative 'flavour_ubuntu_bgp.rb'
require_relative 'flavour_ubuntu_opvn.rb'
require_relative 'flavour_ubuntu_vrrp.rb'
require_relative 'flavour_ubuntu_firewall.rb'
require_relative 'flavour_ubuntu_result.rb'
require_relative 'flavour_ubuntu_services.rb'

require_relative 'bond.rb'
require_relative 'bridge.rb'
require_relative 'device.rb'
require_relative 'gre.rb'
require_relative 'host.rb'
require_relative 'ipsecvpn.rb'
require_relative 'template.rb'
require_relative 'vlan.rb'
require_relative 'wlan.rb'

module Construqt
  module Flavour
    module Ubuntu
      def self.name
        'ubuntu'
      end
      def self.flavour_name
        'ubuntu'
      end

      Construqt::Flavour::Nixian.add(self)


      def self.ipsec
        StrongSwan::Ipsec
      end

      def self.bgp
        Bgp
      end

      def self.clazzes
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

      def self.clazz(name)
        ret = self.clazzes[name]
        throw "class not found #{name}" unless ret
        ret
      end

      def self.create_host(name, cfg)
        cfg['name'] = name
        cfg['result'] = nil
        host = Host.new(cfg)
        host.result = Result.new(host)
        host
      end

      def self.create_interface(name, cfg)
        cfg['name'] = name
        clazz(cfg['clazz']).new(cfg)
      end

      def self.create_bgp(cfg)
        Bgp.new(cfg)
      end

      def self.create_ipsec(cfg)
        StrongSwan::Ipsec.new(cfg)
      end
    end
  end
end
