
module Construct
module Flavour
    module Delegate
      def delegate
        throw "you need a delegate #{self.class.name}" unless @delegate 
        @delegate
      end
      def delegate=(a)
        throw "delegate needs to be !nil" unless a
        @delegate = a
      end
      def header(host)
        self.delegate.respond_to?('header') && self.delegate.header(host)
      end
      def footer(host)
        self.delegate.respond_to?('footer') && self.delegate.footer(host)
      end
      def name
        self.delegate.name
      end
      def simple_name
        self.name[self.name.rindex(':')+1..-1]
      end
      def build_config(host, my)
        #binding.pry
        Flavour.call_aspects("#{self.class.name[self.class.name.rindex(':')+1..-1]}.build_config", host, self.delegate)
        self.delegate.build_config(host, my)
      end
    end
    class OvpnDelegate
      include Delegate
      def initialize(ovpn)
        self.delegate = ovpn
      end
    end
    class GreDelegate
      include Delegate
      def initialize(gre)
        self.delegate = gre
      end
    end
    class HostDelegate
      include Delegate
      def initialize(host)
        #binding.pry
        #Construct.logger.debug "HostDelegate.new(#{host.name})"
        self.delegate = host
      end
    end
    class DeviceDelegate
      include Delegate
      def initialize(device)
        self.delegate = device
      end
    end
    class VrrpDelegate
      include Delegate
      def initialize(vrrp)
        self.delegate = vrrp
      end
    end
    class BridgeDelegate
      include Delegate
      def initialize(bridge)
        self.delegate = bridge
      end
    end
    class BondDelegate
      include Delegate
      def initialize(bond)
        self.delegate = bond
      end
    end
    class VlanDelegate
      include Delegate
      def initialize(vlan)
        self.delegate = vlan
      end
    end
    class TemplateDelegate
      include Delegate
      def initialize(template)
        self.delegate = template
      end
    end
    class InterfaceDelegate
      include Delegate
      def initialize(interface) 
        self.delegate = interface
      end
      def clazz
        self.delegate.clazz
      end
      def name
        self.delegate.name
      end
      def address
        self.delegate.address
      end
      def priority
        self.delegate.priority
      end
      def host
        self.delegate.host
      end
      def network
        self.delegate.network
      end
    end
    class IpsecDelegate
      include Delegate
      def initialize(ipsec)
        self.delegate = ipsec
      end
      def host
        self.delegate.host
      end
      def my
        self.delegate.my
      end
      def remote
        self.delegate.remote
      end
      def other=(a)
        self.delegate.other = a
      end
      def other
        self.delegate.other
      end
      def cfg=(a)
        self.delegate.cfg = a
      end
      def cfg
        self.delegate.cfg
      end
      def interface=(a)
        self.delegate.interface = a
      end
      def interface
        self.delegate.interface
      end
    end
    class BgpDelegate
      include Delegate
      def initialize(bgp)
        self.delegate = bgp
      end
      def once(host)
        self.delegate.once(host)
      end
      def as
        self.delegate.as
      end
      def my
        self.delegate.my
      end
      def host
        self.delegate.host
      end
      def other=(a)
        self.delegate.other = a
      end
      def other
        self.delegate.other
      end
      def cfg=(a)
        self.delegate.cfg = a
      end
      def cfg
        self.delegate.cfg
      end
    end
    class ResultDelegate
      include Delegate
      def initialize(result)
        self.delegate = result
      end
      class Result
        include Delegate
        def initialize(result)
          #puts "Result=>#{self.class.name} #{result}"
          self.delegate = result
        end
        def add(*args)
          delegate.add(*args)
        end
        def commit
          delegate.commit
#          #binding.pry
#          host = delegate.host
#          clazzes = {}
#          host.flavour.pre_clazzes { |key, clazz| clazzes[key] = host.flavour.clazz(key) }
#          clazzes.each do |key, clazz| 
#            Flavour.call_aspects("#{key}.header", host, nil)
#            clazz.header(host)
#          end
#          Flavour.call_aspects("result.commit", nil, delegate)
#          delegate.commit
#          clazzes.each do |key, clazz| 
#            Flavour.call_aspects("#{key}.footer", host, nil)
#            clazz.footer(host)
#          end
        end
      end
      def create(host)
        Result.new(self.delegate.new(host))
      end
    end
  end
end
