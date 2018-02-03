
require_relative 'mikrotik/schema.rb'
require_relative 'mikrotik/ipsec.rb'
require_relative 'mikrotik/bgp.rb'
require_relative 'mikrotik/result.rb'
require_relative 'mikrotik/interface.rb'
require_relative 'mikrotik/device.rb'
require_relative 'mikrotik/wlan.rb'
require_relative 'mikrotik/bond.rb'
require_relative 'mikrotik/vlan.rb'
require_relative 'mikrotik/bridge.rb'
require_relative 'mikrotik/vrrp.rb'
require_relative 'mikrotik/host.rb'
require_relative 'mikrotik/ovpn.rb'
require_relative 'mikrotik/gre.rb'
require_relative 'mikrotik/template.rb'

module Construqt
  module Flavour
    class Mikrotik
      DIRECTORY = File.dirname(__FILE__)

      def name
        "mikrotik"
      end

      def add_host_services(srvs, cfg)
        srvs || []
      end

      def add_interface_services(srvs, cfg)
        srvs || []
      end

      class Factory
        def name
          'mikrotik'
        end
        def factory(parent, cfg)
          Construqt::Flavour::Delegate::FlavourDelegate.new(Mikrotik.new)
        end
      end

      #Construqt::Flavour.add(Factory.new)

      def set_ipv6_address(host, cfg)
        default = {
          "address"=>Schema.network.required,
          "interface"=>Schema.identifier.required,
          "comment" => Schema.string.required.key,
          "advertise"=>Schema.boolean.default(false)
        }
        cfg['comment'] = "#{cfg['interface']}-#{cfg['address']}"
        host.result.render_mikrotik(default, cfg, "ipv6", "address")
      end


      def self.compress_address(val)
        return val.to_s #if val.ipv4?
        #found = 0
        #val.groups.map do |i|
        #  if found > 0 && i != 0
        #    found = -1
        #  end
        #  if found == 0 && i == 0
        #    found += 1
        #    ""
        #  elsif found > 0 && i == 0
        #    found += 1
        #    nil
        #  else
        #    i.to_s 16
        #  end
        #end.compact.join(":").sub(/:+$/, '::')
      end

      def ipsec
        Ipsec
      end

      def bgp
        Bgp
      end

      def clazzes
        {
          "opvn" => Ovpn,
          "gre" => Gre,
          "host" => Host,
          "device"=> Device,
          "vrrp" => Vrrp,
          "bridge" => Bridge,
          "bond" => Bond,
          "wlan" => Wlan,
          "vlan" => Vlan,
          #"result" => Result,
          "template" => Template,
          #"bgp" => Ipsec,
          #"ipsec" => Bgp
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
        Ipsec.new(cfg)
      end
    end
  end
end
