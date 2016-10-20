require_relative 'delegate/bgp_delegate'
require_relative 'delegate/flavour_delegate'
require_relative 'delegate/bond_delegate'
require_relative 'delegate/bridge_delegate'
require_relative 'delegate/device_delegate'
require_relative 'delegate/gre_delegate'
require_relative 'delegate/host_delegate'
require_relative 'delegate/ipsec_delegate'
require_relative 'delegate/ipsec_vpn_delegate'
require_relative 'delegate/ovpn_delegate'
require_relative 'delegate/template_delegate'
require_relative 'delegate/vlan_delegate'
require_relative 'delegate/vrrp_delegate'
require_relative 'delegate/wlan_delegate'

module Construqt
  module Flavour
    module Delegate
      def delegate
        throw "you need a delegate #{self.class.name}" unless @delegate
        @delegate
      end

      def inspect
        "#<#{self.class.name}:#{"%x"%object_id} ident=#{_ident}>"
      end

      def delegate=(a)
        throw "delegate needs to be !nil" unless a
        a.delegate = self
        @delegate = a
      end

      def on_iface_up_down(&block)
        @on_iface_up_down ||= []
        @on_iface_up_down << block
      end

      def call_on_iface_up_down(writer, ifname)
        @on_iface_up_down ||= []
        @on_iface_up_down.each {|block| block.call(writer, ifname) }
      end

      # i have currently no better idea
      def duck_me_eq
      end
      def eq(oth)
        if oth.respond_to?(:duck_me_eq)
          delegate == oth.delegate
        else
          delegate == oth
        end
      end

      def belongs_to
        self.delegate.belongs_to
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

      def proxy_neigh
        self.delegate.proxy_neigh
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

      def build_config(host, my, node)
        #        binding.pry if host && host.name == "ct-iar1-ham"
        #        binding.pry if self.class.name[self.class.name.rindex(':')+1..-1] == "DeviceDelegate"
        #binding.pry
#puts "host => #{host && host.name} #{self.delegate.class.name}"
        #binding.pry unless host
        host.region.flavour_factory.call_aspects("#{simple_name}.build_config", host, my||self)
        #binding.pry
        self.delegate.build_config(host, my||self, node)
      end

      def ident
        self._ident.gsub(/[^0-9a-zA-Z_]/, '_')
      end
    end
  end
end
