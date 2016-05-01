module Construqt
  module Firewalls
    class Firewall
      def initialize(name)
        @name = name
        @raw = Raw.new(self)
        @nat = Nat.new(self)
        @forward = Forward.new(self)
        @host = Host.new(self)
        @ipv4 = true
        @ipv6 = true
      end

      def attach_iface(iface)
        AttachedFirewall.new(iface, self)
      end

      def ipv4?
        @ipv4
      end

      def only_ipv4
        @ipv4 = true
        @ipv6 = false
        self.clone
      end

      def ipv6?
        @ipv6
      end

      def only_ipv6
        @ipv4 = false
        @ipv6 = true
        self.clone
      end

      def name
        @name
      end

      def get_raw(iface)
        @raw.attach_iface(iface)
      end

      def raw(&block)
        block.call(@raw)
      end

      def get_nat(iface)
        @nat.attach_iface(iface)
      end

      def nat(&block)
        block.call(@nat)
      end

      def mangle(&block)
        block.call(@mangle)
      end

      def get_forward(iface)
        @forward.attach_iface(iface)
      end

      def forward(&block)
        block.call(@forward)
      end

      def get_host(iface)
        @host.attach_iface(iface)
      end

      def host(&block)
        block.call(@host)
      end

      #    class Input
      #      class All
      #      end

      #      @rules = []
      #      def all(cfg)
      #        @rules << All.new(cfg)
      #      end

      #    end
    end
  end
end
