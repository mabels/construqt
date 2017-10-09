module Construqt
  module Firewalls
    class NatEntry
      attr_accessor :attached_interface
      include FromTo
      include InputOutputOnly
      include Ports
      include Protocols
      include ToDestFromSource
      include MapTo
      include ActionAndInterface
      include FromIsInOutBound

      def connection?
        false
      end

      def get_log
        nil
      end

      def link_local?
        false
      end

      attr_reader :block
      def initialize(block)
        @block = block
      end
      # special handling for ipv4 on nat, the default is
      # ipv4 only not like the rest where ipv4 and ipv6 is enabled
      def ipv6
        @is_ipv6 = true
        if !defined?(@is_ipv4)
          @is_ipv4 = false
        end
        self
      end

      def ipv6?
        if !defined?(@is_ipv6)
          false
        else
          @is_ipv6
        end
      end

      def ipv4
        @is_ipv4 = true
        if !defined?(@is_ipv6)
          @is_ipv6 = false
        end
        self
      end

      def ipv4?
        if !defined?(@is_ipv4)
          true
        else
          @is_ipv4
        end
      end

    end
  end
end
