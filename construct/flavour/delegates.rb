
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
#      def attach=(obj)
#        @self = obj
#      end
#      def attached
#        @attached
#      end
#      def header(host)
#        self.delegate.respond_to?('header') && self.delegate.header(host)
#      end
#      def footer(host)
#        self.delegate.respond_to?('footer') && self.delegate.footer(host)
#      end
      def name
        self.delegate.name
      end
      def address
        self.delegate.address
      end
      def template
        self.delegate.template
      end
      def host
        self.delegate.host
      end
      def priority
        self.delegate.priority
      end
      def clazz
#binding.pry
        self.delegate.clazz
      end
      def cable=(a)
        self.delegate.cable = a
      end
      def cable
        self.delegate.cable
      end
      def simple_name
        self.class.name[self.class.name.rindex(':')+1..-1]
      end
      def build_config(host, my)
#        binding.pry if host && host.name == "ct-iar1-ham"        
#        binding.pry if self.class.name[self.class.name.rindex(':')+1..-1] == "DeviceDelegate"
        #binding.pry
        Flavour.call_aspects("#{simple_name}.build_config", host, my||self)
        self.delegate.build_config(host, my||self)
      end
      def ident
        self._ident.gsub(/[^0-9a-zA-Z_]/, '_')
      end
    end
    class OpvnDelegate
      include Delegate
      def initialize(opvn)
        self.delegate = opvn
      end
      def _ident
        "Opvn_#{self.host.name}_#{self.name}"
      end
      def network
        self.delegate.network
      end
    end
    class GreDelegate
      include Delegate
      def initialize(gre)
        self.delegate = gre
      end
      def _ident
        "Gre_#{self.host.name}_#{self.name}"
      end
    end
    class HostDelegate
      include Delegate
      def initialize(host)
        #binding.pry
        #Construct.logger.debug "HostDelegate.new(#{host.name})"
        self.delegate = host

        @users = host.users || host.region.users
      end
      def _ident
#binding.pry
        "Host_#{self.name}"
      end
      def region
        self.delegate.region
      end
      def result
        self.delegate.result
      end
      def flavour
        self.delegate.flavour
      end
      def interfaces
        self.delegate.interfaces
      end
      def id=(id)
        self.delegate.id = id
      end
      def id
        self.delegate.id
      end
      def configip=(id)
        self.delegate.configip = id
      end
      def configip
        self.delegate.configip
      end
      def users
        @users
      end
      def commit
        clazzes = {}
        #binding.pry
        self.flavour.pre_clazzes { |key, clazz| clazzes[key] = clazz }
        clazzes.each do |key, clazz| 
          Flavour.call_aspects("#{key}.header", self, nil)
          #clazz.header(self)
        end
        Flavour.call_aspects("host.commit", self, nil)
        self.result.commit
        clazzes.each do |key, clazz| 
          Flavour.call_aspects("#{key}.footer", self, nil)
          #clazz.footer(self)
        end
      end
    end
    class DeviceDelegate
      include Delegate
      def initialize(device)
        self.delegate = device
      end
      def _ident
        #binding.pry
        #Construct.logger.debug "DeviceDelegate::_ident:#{attached.delegate.name}"
        "Device_#{delegate.host.name}_#{self.name}"
      end
    end
    class VrrpDelegate
      include Delegate
      def initialize(vrrp)
        #binding.pry
        self.delegate = vrrp
      end
      def _ident
        "Vrrp_#{self.name}_#{self.delegate.interfaces.map{|i| "#{i.host.name}_#{i.name}"}.join("_")}"
      end
    end
    class BridgeDelegate
      include Delegate
      def initialize(bridge)
        self.delegate = bridge
      end
      def _ident
        "Bridge_#{self.host.name}_#{self.name}"
      end
      def interfaces
        self.delegate.interfaces
      end
    end
    class BondDelegate
      include Delegate
      def initialize(bond)
        self.delegate = bond
      end
      def _ident
        "Bond_#{self.host.name}_#{self.name}"
      end
      def interfaces
        self.delegate.interfaces
      end
    end
    class VlanDelegate
      include Delegate
      def initialize(vlan)
        self.delegate = vlan
      end
      def interfaces
        self.delegate.interfaces
      end
      def _ident
        "Vlan_#{self.host.name}_#{self.name}"
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
      def _ident
        self.clazz.ident
#        "#{self.delegate.clazz.name}_#{self.name}"
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
      def cable
        self.delegate.cable
      end
      def cable=(a)
        self.delegate.cable = a
      end
      def template
        self.delegate.template
      end
      def interfaces
        self.delegate.interfaces
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
      def _ident
        "Ipsec_#{cfg.left.interface.name}_#{cfg.right.interface.name}"
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
      def _ident
        "Bgp_#{cfg.left.host.name}_#{cfg.left.my.name}_#{cfg.right.host.name}_#{cfg.right.my.name}"
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
