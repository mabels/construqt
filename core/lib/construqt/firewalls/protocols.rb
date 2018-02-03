module Construqt
  module Firewalls
    module Protocols
      include Util::Chainable
      chainable_attr :tcp
      chainable_attr :udp
      chainable_attr :esp
      chainable_attr :gre
      chainable_attr :ah
      chainable_attr :icmp
      chainable_attr :type, nil

      def proto_flags(proto, flags)
        @proto_flags ||= {}
        @proto_flags[proto] = flags
        self
      end

      def get_proto_flags
        @proto_flags ||= {}
      end

      def ipv6
        @family = Construqt::Addresses::IPV6
        self
      end

      def ipv6?
        if !defined?(@family)
          block.ipv6?
        else
          @family == Construqt::Addresses::IPV6
        end
      end

      def ipv4
        @family = Construqt::Addresses::IPV4
        self
      end

      def ipv4?
        if !defined?(@family)
          block.ipv4?
        else
          @family == Construqt::Addresses::IPV4
        end
      end

      def get_protocols(family)
        protocols = {
          'tcp' => self.tcp?,
          'udp' => self.udp?,
          'esp' => self.esp?,
          'gre' => self.gre?,
          'ah' => self.ah?
        }
        protocols[family == Construqt::Addresses::IPV6 ? 'icmpv6' : 'icmp'] = self.icmp?
        ret = protocols.keys.select{ |i| protocols[i] }
        #puts ">>>>>>#{protocols.inspect}=>#{ret.inspect}"
        ret
      end
    end
  end
end
