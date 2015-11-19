
module Construqt
  module Flavour
    module Delegate
      def delegate
        throw "you need a delegate #{self.class.name}" unless @delegate
        @delegate
      end

      def delegate=(a)
        throw "delegate needs to be !nil" unless a
        a.delegate = self
        @delegate = a
      end

      def tags
        @tags || []
      end

      def tags=(tags)
        @tags = tags
      end

      def vrrp=(a)
        @vrrp = a
      end

      def vrrp
        @vrrp
      end

      def dynamic
        self.delegate.dynamic
      end

      def services
        self.delegate.services
      end

      def dhcp
        self.address && self.address.ips.each do |adr|
          return adr.options["dhcp"] if adr.options["dhcp"]
        end
        nil
      end

      def vagrant
        self.delegate.vagrant
      end

      def ipsec
        self.delegate.ipsec
      end

      def firewalls
        @firewalls || []
      end

      def firewalls=(firewalls)
        @firewalls = firewalls
      end

      def description
        self.delegate.description
      end

      def default_name
        self.delegate.default_name
      end

      def name
        self.delegate.name
      end

      def mtu
        self.delegate.mtu
      end

      def address
        self.delegate.address
      end

      def address=(a)
        self.delegate.address=a
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

      def priority=(a)
        self.delegate.priority=a
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

      def plug_in=(a)
        self.delegate.plug_in = a
      end

      def plug_in
        self.delegate.plug_in
      end

      def simple_name
        self.class.name[self.class.name.rindex(':')+1..-1]
      end

      def build_config(host, my)
        #        binding.pry if host && host.name == "ct-iar1-ham"
        #        binding.pry if self.class.name[self.class.name.rindex(':')+1..-1] == "DeviceDelegate"
        #binding.pry
puts "host => #{host && host.name} #{self.delegate.class.name}"
        Flavour.call_aspects("#{simple_name}.build_config", host, my||self)
        self.delegate.build_config(host, my||self)
      end

      def ident
        self._ident.gsub(/[^0-9a-zA-Z_]/, '_')
      end
    end

    class OpvnDelegate
      include Delegate
      COMPONENT = Construqt::Resources::Component::OPENVPN
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
      COMPONENT = Construqt::Resources::Component::UNREF
      def initialize(gre)
        self.delegate = gre
      end

      def _ident
        "Gre_#{self.host.name}_#{self.name}"
      end

      def cfg
        self.delegate.cfg
      end
    end

    class HostDelegate
      include Delegate
      COMPONENT = Construqt::Resources::Component::UNREF
      attr_reader :users, :bgps, :ipsecs
      def initialize(host)
        #binding.pry
        #Construqt.logger.debug "HostDelegate.new(#{host.name})"
        self.delegate = host

        @ipsecs = []
        @bgps = []
        @users = host.users || host.region.users
      end

      def spanning_tree
        self.delegate.spanning_tree
      end

	    def lxc_deploy
        self.delegate.lxc_deploy
      end


      def mother
        if self.delegate.respond_to? :mother
          self.delegate.mother
        else
          false
        end
      end

      def get_groups
        if self.delegate.add_groups.instance_of? String
          self.delegate.add_groups = [ self.delegate.add_groups ]
        end
        self.delegate.add_groups || []
      end

      def has_interface_with_component?(cp)
        self.interfaces.values.find { |i| i.class::COMPONENT == cp }
      end

      def address
        my = Construqt::Addresses::Address.new(delegate.region.network)
        self.interfaces.values.each do |i|
          if i.address
            my.add_addr(i.address)
          end
        end
        my
      end

      def _ident
        #binding.pry
        "Host_#{self.name}"
      end

      def factory
        self.delegate.factory
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

      def add_ipsec(ipsec)
        @ipsecs << ipsec
      end

      def add_bgp(bgp)
        @bgps << bgp
      end

      def commit
        #header_clazzes = {:host => self } # host class need also a header call
        #footer_clazzes = {:host => self } # host class need also a header call
        #self.interfaces.values.each do |iface|
        #  header_clazzes[iface.class.name] ||= iface if iface.delegate.respond_to? :header
        #  footer_clazzes[iface.class.name] ||= iface if iface.delegate.respond_to? :footer
        #end

        #binding.pry
        self.flavour.pre_clazzes do |key, clazz|
          Flavour.call_aspects("#{key}.header", self, nil)
          clazz.header(self) if clazz.respond_to? :header
        end

        Flavour.call_aspects("host.commit", self, nil)
        self.result.commit

        self.flavour.pre_clazzes do |key, clazz|
          Flavour.call_aspects("#{key}.footer", self, nil)
          clazz.footer(self) if clazz.respond_to? :footer
        end
      end
    end

    class DeviceDelegate
      include Delegate
      COMPONENT = Construqt::Resources::Component::UNREF
      def initialize(device)
        self.delegate = device
      end

      def _ident
        #binding.pry
        #Construqt.logger.debug "DeviceDelegate::_ident:#{attached.delegate.name}"
        "Device_#{delegate.host.name}_#{self.name}"
      end
    end

    class VrrpDelegate
      include Delegate
      COMPONENT = Construqt::Resources::Component::VRRP
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
      COMPONENT = Construqt::Resources::Component::UNREF
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
      COMPONENT = Construqt::Resources::Component::UNREF
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

    class WlanDelegate
      include Delegate
      COMPONENT = Construqt::Resources::Component::UNREF
      def initialize(wlan)
        self.delegate = wlan
      end

      def _ident
        "Wlan_#{self.host.name}_#{self.name}"
      end

      def stereo_type
        self.delegate.stereo_type
      end

      def master_if
        self.delegate.master_if
      end

      def vlan_id
        self.delegate.vlan_id
      end

      def psk
        self.delegate.psk
      end

      def ssid
        self.delegate.ssid
      end

      def band
        self.delegate.band
      end

      def channel_width
        self.delegate.channel_width
      end

      def country
        self.delegate.country
      end

      def mode
        self.delegate.mode
      end

      def rx_chain
        self.delegate.rx_chain
      end

      def tx_chain
        self.delegate.tx_chain
      end

      def hide_ssid
        self.delegate.hide_ssid
      end

    end

    class VlanDelegate
      include Delegate
      COMPONENT = Construqt::Resources::Component::UNREF
      def initialize(vlan)
        self.delegate = vlan
      end

      def interfaces
        self.delegate.interfaces
      end

      def vlan_id
        self.delegate.vlan_id
      end

      def _ident
        "Vlan_#{self.host.name}_#{self.name}"
      end
    end

    class TemplateDelegate
      include Delegate
      COMPONENT = Construqt::Resources::Component::UNREF
      def initialize(template)
        self.delegate = template
      end
    end

    class IpsecVpnDelegate
      include Delegate
      COMPONENT = Construqt::Resources::Component::IPSEC
      def initialize(ipsecvpn)
        self.delegate = ipsecvpn
      end
      def left_interface
        self.delegate.left_interface
      end
      def ipv6_proxy
        self.delegate.ipv6_proxy
      end
      def right_address
        self.delegate.right_address
      end
      def auth_method
        self.delegate.auth_method
      end
      def users
        self.delegate.users
      end
      def leftcert
        self.delegate.leftcert
      end
      def leftpsk
        self.delegate.leftpsk
      end
      def _ident
        "IpsecVpn_#{self.host.name}_#{self.name}"
      end
    end

    class IpsecDelegate
      include Delegate
      COMPONENT = Construqt::Resources::Component::IPSEC
      def initialize(ipsec)
        self.delegate = ipsec
      end

      def host
        self.delegate.host
      end

      def firewalls
        self.delegate.firewalls
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

      def any
        self.delegate.any
      end

      def sourceip
        self.delegate.sourceip
      end

      def interface=(a)
        self.delegate.interface = a
      end

      def interface
        self.delegate.interface
      end

      def _ident
        "Ipsec_#{cfg.lefts.first.interface.name}_#{cfg.rights.first.interface.name}"
      end
    end

    class BgpDelegate
      include Delegate
      COMPONENT = Construqt::Resources::Component::BGP
      def initialize(bgp)
        self.delegate = bgp
      end

      def once(host)
        self.delegate.once(host)
      end

      def as
        self.delegate.as
      end

      def routing_table
        self.delegate.routing_table
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
        "Bgp_#{cfg.lefts.first.host.name}_#{cfg.lefts.first.my.name}_#{cfg.rights.first.host.name}_#{cfg.rights.first.my.name}"
      end
    end

    #    class ResultDelegate
    #      include Delegate
    #      def initialize(result)
    #        self.delegate = result
    #      end

    #
    #      class Result
    #        include Delegate
    #        def initialize(result)
    #          #puts "Result=>#{self.class.name} #{result}"
    #          self.delegate = result
    #        end

    #
    #        def add(*args)
    #          delegate.add(*args)
    #        end

    #
    #      #  def commit
    #          #          Flavour.call_aspects("#{key}.header", host, nil)
    #          #          clazz.header(host)
    #
    #      #    binding.pry
    #      #    delegate.commit
    #          #          host = delegate.host
    #          #          clazzes = {}
    #          #          host.flavour.pre_clazzes { |key, clazz| clazzes[key] = host.flavour.clazz(key) }
    #          #          clazzes.each do |key, clazz|
    #          #            Flavour.call_aspects("#{key}.header", host, nil)
    #          #            clazz.header(host)
    #          #          end

    #
    #          #          Flavour.call_aspects("result.commit", nil, delegate)
    #          #          delegate.commit
    #          #          clazzes.each do |key, clazz|
    #          #            Flavour.call_aspects("#{key}.footer", host, nil)
    #          #            clazz.footer(host)
    #          #          end

    #      #  end

    #      end

    #
    #      def create(host)
    #        Result.new(self.delegate.new(host))
    #      end

    #    end
  end
end
